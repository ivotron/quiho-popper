#!/bin/bash
set -e -x

echo "benchmark,machine,repetition,test,result" > all.csv

# stressng
docker run --rm \
  -v `pwd`/benchoutput:/data \
  ivotron/json-to-tabular:v0.0.4 \
    --jqexp '. | .metrics | .[] | [.stressor, ."bogo-ops-per-second-real-time"]' \
    --filefilter '.*stressng\/.*.yml' \
    ./ >> all.csv

# ssca
docker run --rm \
  -v `pwd`/benchoutput:/data \
  ivotron/json-to-tabular:v0.0.5 \
    --filefilter '.*ssca.*runtime' \
    --shex "sed 's/\(.*\):\(.*\):\(.*\)/\1 \2 \3/' | awk '{ print \"ssca,\"((\$1 * 3600) + (\$2 * 60) + \$3) }'" \
    ./ >> all.csv

# hpccg
docker run --rm \
  -v `pwd`/benchoutput:/data \
  ivotron/json-to-tabular:v0.0.5 \
    --filefilter '.*hpccg.*runtime' \
    --shex "sed 's/\(.*\):\(.*\):\(.*\)/\1 \2 \3/' | awk '{ print \"hpccg,\"((\$1 * 3600) + (\$2 * 60) + \$3) }'" \
    ./ >> all.csv

# sklearn
docker run --rm \
  -v `pwd`/benchoutput:/data \
  ivotron/json-to-tabular:v0.0.5 \
    --filefilter '.*scikit-learn.*runtime' \
    --shex "sed 's/\(.*\):\(.*\):\(.*\)/\1 \2 \3/' | awk '{ print \"sklearn,\"((\$1 * 3600) + (\$2 * 60) + \$3) }'" \
    ./ >> all.csv

# redis
docker run --rm \
  -v `pwd`/benchoutput:/data \
  ivotron/json-to-tabular:v0.0.4 \
    --filefilter '.*redisbench.*.csv' \
    ./ >> all.csv

