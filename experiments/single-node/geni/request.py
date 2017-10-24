#!/usr/bin/env python
import os
import os.path
import geni.cloudlab_util as cl
from geni.rspec import pg as rspec

if not os.path.isdir('/output'):
    raise Exception("expecting '/output folder'")

img = "urn:publicid:IDN+apt.emulab.net+image+schedock-PG0:docker-ubuntu16:0"

requests = {}


def create_request(site, hw_type):
    node = rspec.RawPC(hw_type)
    node.disk_image = img

    if site not in requests:
        requests[site] = rspec.Request()

    requests[site].addResource(node)


print("Creating cloudlab requests")

# create_request('apt', 'c6220')
create_request('apt', 'r720')
create_request('cl-clemson', 'c6320')
create_request('cl-utah', 'm510')
create_request('cl-wisconsin', 'c220g2')
create_request('ig-utahddc', 'dl360')
create_request('pg-kentucky', 'pc2400')
create_request('pg-kentucky', 'pc3300')
create_request('pg-utah', 'd2100')
create_request('pg-utah', 'pc3000')

print("Executing cloudlab request")
manifests = cl.request(experiment_name=('quiho-'+os.environ['CLOUDLAB_USER']),
                       requests=requests, timeout=30, expiration=1200,
                       ignore_failed_slivers=True)

print("Writing /output/machines file")
with open('/output/machines', 'w') as f:
    for site, manifest in manifests.iteritems():
        for n in manifest.nodes:
            f.write(n.hostfqdn)
            f.write(' ansible_user=' + os.environ['CLOUDLAB_USER'])
            f.write(' ansible_become=true' + os.linesep)

        with open('/output/{}.xml'.format(site), 'w') as mf:
            mf.write(manifest.text)
