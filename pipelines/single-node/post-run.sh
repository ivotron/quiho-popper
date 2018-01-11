#!/bin/bash
# [wf] extend dataset with newly obtained results
set -ex

# run post-process.sh in results/ folder (this creates an all.csv file)
pushd results

# [wf] obtain a CSV from baseliner output
./postprocess.sh

popd

# define variables for giturl, commit, user and timestamp
url=$(git remote -v | grep fetch | awk '{print $2}' | sed 's:[\/&]:\\&:g;$!s/$/\\/')
commit=$(git rev-parse --short HEAD)
ts=$(date +%s)

if [ -n "$CI" ]; then
  username='travis'
else
  username=$USER
fi

# make copy and remove first line
sed '1d' results/all.csv > alltmp.csv

# [wf] add prefix to every line and update datapackage dataset
sed -e "s/^/$url,$commit,$username,$ts,/" alltmp.csv >> datapackage/quiho/results.csv
rm alltmp.csv

# [wf] also add list of machines to datapackage
cat results/baseliner_output/facts/*.json | docker run --rm -i ivotron/jq:1.5 -r --arg ts "$ts" '[.ansible_nodename, $ts, .ansible_processor[1], .ansible_processor_cores, .ansible_processor_count, .ansible_processor_threads_per_core, .ansible_processor_vcpus, .ansible_product_name, .ansible_product_serial, .ansible_product_uuid, .ansible_product_version] | @csv' >> datapackage/quiho/machines.csv
