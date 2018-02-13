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
for f in apps_variability corrmatrix corrmatrix_underfit four hpccg mariadb-innodb-regression mariadb-innodb-vs-memory pca-var-reduction redis-set_underfit stream-nadds-behavior stream-nadds stressng_variability ; do
  if [ ! -f results/figures/$f.pdf ]; then
    echo "Unable to find results/figures/$f.pdf"
    exit 1
  fi
done
