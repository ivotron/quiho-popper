#!/usr/bin/env python

import os
import os.path
import sys
import yaml

import geni.cloudlab_util as cl
from geni.rspec import pg as rspec

if not sys.argv[1]:
    raise Exception("expecting --release or --request")
action = sys.argv[1]

if action == "--release":
    cl.release(experiment_name='quiho')
    sys.exit(0)
elif action != "--request":
    raise Exception("expecting --release or --request")

if not os.path.isdir('/output'):
    raise Exception("expecting '/output folder'")

if not os.path.isfile('/vars.yml'):
    raise Exception("expecting '/vars.yml file'")

with open('/vars.yml', 'r') as f:
    config = yaml.load(f)

sites = config['machines']['cloudlab']['sites']

node = rspec.RawPC("node")
img = "urn:publicid:IDN+apt.emulab.net+image+schedock-PG0:docker-ubuntu16:0"
node.disk_image = img

r = rspec.Request()
r.addResource(node)

manifests = cl.request(experiment_name='quiho', sites=sites,
                       request=r, expiration=360)

print("Writing /output/machines file")
with open('/output/machines', 'w') as f:
    for m in config['machines'].get('local', []):
        f.write(m + os.linesep)

    for site, manifest in manifests.iteritems():
        f.write(manifest.nodes[0].hostfqdn)
        f.write(' ansible_user=' + os.environ['CLOUDLAB_USER'])
        f.write(' ansible_become=true' + os.linesep)

        with open('/output/{}.xml'.format(site), 'w') as mf:
            mf.write(manifest.text)

sys.exit(0)
