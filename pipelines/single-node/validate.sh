#!/bin/bash
# [wf] generate figures
set -e

rm -f results/figures/*.png

# [wf] invoke Jupyter to generate figures
docker run --rm --name=jupyter \
  -v `pwd`:/experiment:z \
  --user=root \
  --workdir=/experiment/results \
  --entrypoint=jupyter \
  jupyter/scipy-notebook:e89b2fe9974b nbconvert \
    --execute visualize.ipynb \
    --ExecutePreprocessor.timeout=-1 \
    --inplace

# [wf] check that figures got created
for f in corrmatrix corrmatrix_underfit redis-set_underfit stressng_variability redis-get redis-set hpccg scikit-learn ssca mariadb-10.3.2-innodb_load mariadb-10.3.2-memory_load add-1 add-2 add-4 add-6 add-8 add-10 add-12 add-14 add-16 add-18 add-20 ; do
  if [ ! -f results/figures/$f.png ]; then
    echo "Unable to find results/figures/$f.png"
    exit 1
  fi
done
