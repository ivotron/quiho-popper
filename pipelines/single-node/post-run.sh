#!/bin/bash
set -ex

# TODO:
# 1. Run post-process.sh in results/ folder (this creates all.csv file)
# 2. Append 'org,repo,experiment,commit,user,timestamp' to each row of all.csv
# 3. Append contents of all.csv to datapackage

# get table of machines
echo "machine,cpu,cores,num_cpus,threads_per_core,vcpus,board_name,board_serial,board_uuid,board_version" > results/machines.csv
cat $OUTDIR/benchoutput/facts/*.json | docker run --rm -i ivotron/jq:1.5 \
    '[.ansible_nodename, .ansible_processor[1], .ansible_processor_cores, .ansible_processor_count, .ansible_processor_threads_per_core, .ansible_processor_vcpus, .ansible_product_name, .ansible_product_serial, .ansible_product_uuid, .ansible_product_version] | @csv' \
    >> results/machines.csv
