#!/bin/bash
set -e -x

OUTDIR="`pwd`/baseliner_output"
CSVOUT="all.csv"

echo "" > $CSVOUT

# stressng
docker run --rm -v $OUTDIR/benchmark:/data/benchmark \
  ivotron/json-to-tabular:v0.0.5 \
    --jqexp '. | .metrics | .[] | [.stressor, ."bogo-ops-per-second-real-time"]' \
    --filefilter '.*stressng.*yml' \
    ./ >> $CSVOUT

# stream
docker run --rm -v $OUTDIR/benchmark:/data/benchmark \
  ivotron/json-to-tabular:v0.0.5 \
    --filefilter '.*stream.*std.out' \
    --shex " grep 'Copy:\\|Scale:\\|Add:\\|Triad' | sed 's/://' | awk '{ print tolower(\$1)\",\"\$2 }'" \
    ./ >> temp

sed -i -s 's/\(.*\),\(.*\),\(.*\),\(.*\),\(.*\),\(.*\)/\1,\2,\3,\5-\4,\6/' temp
cat temp >> $CSVOUT
rm temp

# ssca
docker run --rm -v $OUTDIR/benchmark:/data/benchmark \
  ivotron/json-to-tabular:v0.0.5 \
    --filefilter '.*ssca.*runtime' \
    --shex "sed 's/\(.*\):\(.*\):\(.*\)/\1 \2 \3/' | awk '{ print \"ssca,\"((\$1 * 3600) + (\$2 * 60) + \$3) }'" \
    ./ >> all.csv

# hpccg
docker run --rm -v $OUTDIR/benchmark:/data/benchmark \
  ivotron/json-to-tabular:v0.0.5 \
    --filefilter '.*hpccg.*runtime' \
    --shex "sed 's/\(.*\):\(.*\):\(.*\)/\1 \2 \3/' | awk '{ print \"hpccg,\"((\$1 * 3600) + (\$2 * 60) + \$3) }'" \
    ./ >> all.csv

# sklearn
docker run --rm -v $OUTDIR/benchmark:/data/benchmark \
  ivotron/json-to-tabular:v0.0.5 \
    --filefilter '.*scikit-learn.*runtime' \
    --shex "sed 's/\(.*\):\(.*\):\(.*\)/\1 \2 \3/' | awk '{ print \"sklearn,\"((\$1 * 3600) + (\$2 * 60) + \$3) }'" \
    ./ >> all.csv

# comd
docker run --rm -v $OUTDIR/benchmark:/data/benchmark \
  ivotron/json-to-tabular:v0.0.5 \
    --filefilter '.*comd.*runtime' \
    --shex "sed 's/\(.*\):\(.*\):\(.*\)/\1 \2 \3/' | awk '{ print \"comd,\"((\$1 * 3600) + (\$2 * 60) + \$3) }'" \
    ./ >> all.csv

# lulesh
docker run --rm -v $OUTDIR/benchmark:/data/benchmark \
  ivotron/json-to-tabular:v0.0.5 \
    --filefilter '.*lulesh.*runtime' \
    --shex "sed 's/\(.*\):\(.*\):\(.*\)/\1 \2 \3/' | awk '{ print \"lulesh,\"((\$1 * 3600) + (\$2 * 60) + \$3) }'" \
    ./ >> all.csv

# miniaero
docker run --rm -v $OUTDIR/benchmark:/data/benchmark \
  ivotron/json-to-tabular:v0.0.5 \
    --filefilter '.*miniaero.*runtime' \
    --shex "sed 's/\(.*\):\(.*\):\(.*\)/\1 \2 \3/' | awk '{ print \"miniaero,\"((\$1 * 3600) + (\$2 * 60) + \$3) }'" \
    ./ >> all.csv

# miniamr
docker run --rm -v $OUTDIR/benchmark:/data/benchmark \
  ivotron/json-to-tabular:v0.0.5 \
    --filefilter '.*miniamr.*runtime' \
    --shex "sed 's/\(.*\):\(.*\):\(.*\)/\1 \2 \3/' | awk '{ print \"miniamr,\"((\$1 * 3600) + (\$2 * 60) + \$3) }'" \
    ./ >> all.csv

# minife
docker run --rm -v $OUTDIR/benchmark:/data/benchmark \
  ivotron/json-to-tabular:v0.0.5 \
    --filefilter '.*minife.*runtime' \
    --shex "sed 's/\(.*\):\(.*\):\(.*\)/\1 \2 \3/' | awk '{ print \"minife,\"((\$1 * 3600) + (\$2 * 60) + \$3) }'" \
    ./ >> all.csv

# zlog
docker run --rm -v $OUTDIR/benchmark:/data/benchmark \
  ivotron/json-to-tabular:v0.0.5 \
    --filefilter '.*zlog.*runtime' \
    --shex "sed 's/\(.*\):\(.*\):\(.*\)/\1 \2 \3/' | awk '{ print \"zlog,\"((\$1 * 3600) + (\$2 * 60) + \$3) }'" \
    ./ >> all.csv
