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

# get repetitions
reps=`cat vars.yml | grep 'repetitions:' | awk '{print $2}'`
if [ -z "$reps" ]; then
  echo "Expecting 'repetitions' variable"
  exit 1
fi

docker pull ivotron/ansible:2.2.0.0

echo '' > ansible/ansible.log

for i in `seq 1 $reps` ; do
  mkdir -p $outdir/repetition/$i
  docker run --rm \
    -v `pwd`:/experiment \
    -v $MYSSHKEY:/root/.ssh/id_rsa \
    --workdir=/experiment/ansible \
    --net=host \
    --entrypoint=/bin/bash \
    ivotron/ansible:2.2.0.0 -c \
      "ansible-playbook \
        -e @/experiment/vars.yml \
        -e local_results_path=/experiment/$outdir/repetition/$i \
        playbook.yml"
done

mv $outdir/repetition/$reps/facts/* $factsdir
rm -fr $outdir/repetition/*/facts
