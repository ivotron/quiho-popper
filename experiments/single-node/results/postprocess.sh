#!/bin/bash
set -e -x

OUTDIR="$1"
CSVOUT="$2"

echo "benchmark,machine,repetition,test,result" > $CSVOUT

# stressng
docker run --rm \
  --mount type=bind,source=$OUTDIR,destination=/data \
  ivotron/json-to-tabular:v0.0.5 \
    --jqexp '. | .metrics | .[] | [.stressor, ."bogo-ops-per-second-real-time"]' \
    --filefilter '.*stressng.*yml' \
    ./ >> $CSVOUT

# mysql
docker run --rm \
  --mount type=bind,source=$OUTDIR,destination=/data \
  ivotron/json-to-tabular:v0.0.5 \
    --jqexp 'to_entries | map([.key, .value]) | .[] ' \
    --filefilter '.*mysqlslap.*json' \
    ./ >> $CSVOUT

# stream
docker run --rm \
  --mount type=bind,source=$OUTDIR,destination=/data \
  ivotron/json-to-tabular:v0.0.5 \
    --filefilter '.*stream.*std.out' \
    --shex " grep 'Copy:\\|Scale:\\|Add:\\|Triad' | sed 's/://' | awk '{ print tolower(\$1)\",\"\$2 }'" \
    ./ >> temp

sed -i -s 's/\(.*\),\(.*\),\(.*\),\(.*\),\(.*\),\(.*\)/\1,\2,\3,\5-\4,\6/' temp
cat temp >> $CSVOUT
rm temp
