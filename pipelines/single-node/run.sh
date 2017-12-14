#!/bin/bash
set -ex

if [ -z "$MYSSHKEY" ]; then
  echo "Expecting MYSSHKEY variable"
  exit 1
fi

# delete previous results
rm -fr results/baseliner_output
mkdir -p results/baseliner_output

docker pull ivotron/baseliner:2.4.0.0

docker run --rm --name=baseliner \
  --volume `pwd`:/experiment \
  --volume $MYSSHKEY:/root/.ssh/id_rsa \
  --workdir=/experiment/ \
  --net=host \
  ivotron/baseliner:2.4.0.0 \
    -i /experiment/geni/machines \
    -f /experiment/vars.yml \
    -o /experiment/results/baseliner_output
