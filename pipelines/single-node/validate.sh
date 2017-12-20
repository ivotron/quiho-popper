#!/bin/bash
set -e

rm -f results/figures/*.png

docker run --rm --name=jupyter \
  -v `pwd`:/experiment:z \
  --user=root \
  --workdir=/experiment/results \
  --entrypoint=jupyter \
  jupyter/scipy-notebook:e89b2fe9974b nbconvert \
    --execute visualize.ipynb \
    --ExecutePreprocessor.timeout=-1 \
    --inplace

for f in corrmatrix stressng_variability GET LPOP LPUSH SET hpccg sklearn ssca ; do
  if [ ! -f results/figures/$f.png ]; then
    echo "Unable to find results/figures/$f.png"
    exit 1
  fi
done
