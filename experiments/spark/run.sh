#!/bin/bash
set -ex

if [ -z "$MYSSHKEY" ]; then
  echo "Expecting MYSSHKEY variable"
  exit 1
fi

outdir="results/"

# delete previous results
rm -fr $outdir/*

docker pull ivotron/baseliner:2.2.1.0

mkdir -p $outdir
docker run --rm \
  --volume `pwd`:/experiment \
  --volume $MYSSHKEY:/root/.ssh/id_rsa \
  --workdir=/experiment/ \
  --net=host \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  ivotron/baseliner:2.2.1.0 \
    -i /experiment/geni/machines \
    -f /experiment/vars.yml
