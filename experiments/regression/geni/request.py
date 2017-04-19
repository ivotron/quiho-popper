#!/usr/bin/env python

from geni.aggregate import cloudlab as cl
from geni.aggregate.apis import DeleteSliverError
from geni.aggregate.frameworks import ClearinghouseError
from geni.minigcf.config import HTTP
from geni.rspec import pg as rspec
from geni.util import loadContext

import argparse
import datetime
import json
import os
import time
import yaml

HTTP.TIMEOUT = 300

aggregate = {
    'utah': cl.Utah,
    'wisconsin': cl.Wisconsin,
    'clemson': cl.Clemson,
    'utahddc': cl.UtahDDC,
    'apt': cl.Apt
}


def build_context():
    e = os.environ

    with open('/tmp/context.json', 'w') as f:
        data = {
            "framework": "emulab-ch2",
            "cert-path": e['CLOUDLAB_CERT_PATH'],
            "key-path": e['CLOUDLAB_CERT_PATH'],
            "user-name": e['CLOUDLAB_USER'],
            "user-urn": "urn:publicid:IDN+emulab.net+user+"+e['CLOUDLAB_USER'],
            "user-pubkeypath": e['CLOUDLAB_KEY_PATH'],
            "project": e['CLOUDLAB_PROJECT']
        }
        json.dump(data, f)

    slice_exp = datetime.datetime.now() + datetime.timedelta(hours=2)

    try:
        ctxt = loadContext("/tmp/context.json",
                           key_passphrase=e['CLOUDLAB_PASSWD'])
        ctxt.cf.createSlice(ctxt, "quiho-regression", exp=slice_exp)
    except ClearinghouseError as e:
        if 'already a registered slice' not in str(e):
            raise
        ctxt.cf.renewSlice(ctxt, "quiho-regression", exp=slice_exp)

    return ctxt


def request_resources(ctxt, config):
    cloudlab_sites = config['machines']['cloudlab']['sites']

    node = rspec.RawPC("node")
    img = "urn:publicid:IDN+apt.emulab.net+image+schedock-PG0:docker-ubuntu16:0"
    node.disk_image = img

    r = rspec.Request()
    r.addResource(node)

    manifests = []
    for site in cloudlab_sites:
        print("Creating sliver on " + site)
        manifests += [aggregate[site].createsliver(ctxt, "quiho-regression", r)]

    print("Writing /tmp/machines file")
    with open('/tmp/machines', 'w') as f:
        for m in config['machines'].get('local', []):
            f.write(m + os.linesep)

        for m in manifests:
            f.write(m.nodes[0].hostfqdn)
            f.write(' ansible_user=' + os.environ['CLOUDLAB_USER'])
            f.write(' ansible_become=true' + os.linesep)

    print("Waiting for all nodes to boot")
    timeout = time.time() + 60*15
    while True:
        time.sleep(30)
        for site in cloudlab_sites:
            status = aggregate[site].sliverstatus(ctxt, "quiho-regression")
            if status['pg_status'] != 'ready':
                break

        if time.time() > timeout:
            release_resources(ctxt, config)
            raise Exception("Not all nodes came up after 10 minutes")


def release_resources(ctxt, config):
    for site in config['machines']['cloudlab']['sites']:
        try:
            aggregate[site].deletesliver(ctxt, "quiho-regression")
        except ClearinghouseError:
            time.sleep(30)
            aggregate[site].deletesliver(ctxt, "quiho-regression")
        except DeleteSliverError:
            continue
        except:
            raise

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--request', dest='feature', action='store_true')
    parser.set_defaults(request=True)
    parser.add_argument('--release', dest='feature', action='store_true')
    parser.set_defaults(release=False)
    args = parser.parse_args()

    with open('/tmp/vars.yml', 'r') as f:
        config = yaml.load(f)

    ctxt = build_context()

    if args.release:
        release_resources(ctxt, config)
    else:
        release_resources(ctxt, config)
        request_resources(ctxt, config)
