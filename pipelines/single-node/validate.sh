#!/bin/bash
set -e

rm -f results/figures/*.png

docker run --rm --name=jupyter_`basename $PWD` \
  -v `pwd`:/experiment \
  --workdir=/experiment \
  --entrypoint=jupyter \
  jupyter/scipy-notebook:e89b2fe9974b nbconvert \
    --to notebook \
    --execute results/visualize.ipynb \
    --output newvisualize.ipynb \
    --ExecutePreprocessor.timeout=-1

for f in corrmatrix stressng_variability GET LPOP LPUSH SET hpccg sklearn ssca ; do
  if [ ! -f results/figures/$f.png ]; then
    echo "Unable to find results/figures/$f.png"
    exit 1
  fi
done
