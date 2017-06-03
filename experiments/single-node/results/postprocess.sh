#!/bin/bash
set -e -x

rm -f all.csv

# stream
docker run --rm \
  -v `pwd`/benchoutput:/data \
  ivotron/json-to-tabular:v0.0.4 \
    --header 'test,result' \
    --shexp "grep 'memory rate:' |
             awk '{print \$7\$8}' |
             sed 's/KB.*/*1024/' |
             sed 's/MB.*/*1024*1024/' |
             sed 's/GB.*/1024*1024*1024/' |
             bc |
             sed 's/\(.*\)/raw,\1/'" \
    --filefilter '.*stressng-stream.*stdoutout' \
    ./ > all.csv

# redis
docker run --rm \
  -v `pwd`/benchoutput:/data \
  ivotron/json-to-tabular:v0.0.4 \
    --filefilter '.*redisbench.*' \
    ./ >> all.csv

# stressng
docker run --rm \
  -v `pwd`/benchoutput:/data \
  ivotron/json-to-tabular:v0.0.4 \
    --jqexp '. | .metrics | .[] | [.stressor, ."bogo-ops-per-second-real-time"]' \
    --filefilter '.*stressng-cpu\/.*' \
    ./ >> all.csv
docker run --rm \
  -v `pwd`/benchoutput:/data \
  ivotron/json-to-tabular:v0.0.4 \
    --jqexp '. | .metrics | .[] | [.stressor, ."bogo-ops-per-second-real-time"]' \
    --filefilter '.*stressng-cpucache.*' \
    ./ >> all.csv
docker run --rm \
  -v `pwd`/benchoutput:/data \
  ivotron/json-to-tabular:v0.0.4 \
    --jqexp '. | .metrics | .[] | [.stressor, ."bogo-ops-per-second-real-time"]' \
    --filefilter '.*stressng-mem.*' \
    ./ >> all.csv
