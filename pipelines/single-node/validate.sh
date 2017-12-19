#!/bin/bash
set -e

rm -rf results/figures/
mkdir results/figures

docker run --rm --name=jupyter \
  -v `pwd`:/experiment:z \
  --workdir=/experiment/results \
  --entrypoint=jupyter \
  jupyter/scipy-notebook:e89b2fe9974b nbconvert \
    --execute visualize.ipynb \
    --ExecutePreprocessor.timeout=-1 \
    --to notebook \
    --inplace

for f in corrmatrix stressng_variability GET LPOP LPUSH SET hpccg sklearn ssca ; do
  if [ ! -f results/figures/$f.png ]; then
    echo "Unable to find results/figures/$f.png"
    exit 1
  fi
done
