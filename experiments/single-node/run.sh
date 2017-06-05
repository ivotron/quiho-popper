#!/bin/bash
set -ex

if [ -z "$MYSSHKEY" ]; then
  echo "Expecting MYSSHKEY variable"
  exit 1
fi

outdir="results/benchoutput"
factsdir="results/facts"

# delete previous results
rm -fr $outdir/*
rm -fr $factsdir/*

# get docker path
docker_path=$(which docker)
libltdl_path=$(ldd $docker_path | grep libltdl | awk '{print $3}')
if [ -n "$libltdl_path" ] ; then
  libltdl_path="--volume $libltdl_path:/usr/lib/$(basename $libltdl_path)"
fi

echo '' > ansible/ansible.log

mkdir -p $outdir

experiment_path=`pwd`
docker run --rm \
  --volume $experiment_path:$experiment_path \
  --volume $MYSSHKEY:/root/.ssh/id_rsa \
  --workdir=$experiment_path/ansible \
  --net=host \
  --entrypoint=/bin/bash \
  $libltdl_path \
  --volume $docker_path:/usr/bin/docker \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  ivotron/ansible:2.2.0.0 -c \
    "ansible-playbook \
      -e @$experiment_path/vars.yml \
      -e local_results_path=$experiment_path/$outdir \
      playbook.yml"

mv $outdir/facts results/
