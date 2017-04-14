#!/bin/bash
set -e -x

outdir="results/benchoutput"

# delete previous results
rm -fr $outdir/*

# get repetitions
reps=`cat vars.yml | grep 'repetitions:' | awk '{print $2}'`
if [ -z "$reps" ]; then
  echo "Expecting 'repetitions' variable"
  exit 1
fi

for i in `seq 1 $reps` ; do
  mkdir -p $outdir/repetition/$i
  docker run --rm -ti \
    -v `pwd`/ansible:/experiment \
    -v `pwd`/vars.yml:/experiment/vars.yml \
    -v `pwd`/$outdir/repetition/$i:/results \
    -v $SSH_AUTH_SOCK:/ssh-agent \
    -e SSH_AUTH_SOCK=/ssh-agent \
    --workdir=/experiment \
    --net=host \
    --entrypoint=/bin/bash \
    ivotron/ansible:2.2.0.0 -c \
      "ansible-playbook \
        -e @vars.yml \
        -e local_results_path=/results \
        playbook.yml"
    mv $outdir/repetition/$reps/facts results/
done
