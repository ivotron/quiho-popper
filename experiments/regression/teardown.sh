#!/bin/bash
set -e

docker run --rm \
  -e CLOUDLAB_USER=$CLOUDLAB_USER \
  -e CLOUDLAB_PASSWD=$CLOUDLAB_PASSWD \
  -e CLOUDLAB_PROJECT=$CLOUDLAB_PROJECT \
  -e CLOUDLAB_KEY_PATH=$CLOUDLAB_KEY_PATH \
  -e CLOUDLAB_CERT_PATH=$CLOUDLAB_CERT_PATH \
  -v $CLOUDLAB_KEY_PATH:$CLOUDLAB_KEY_PATH \
  -v $CLOUDLAB_CERT_PATH:$CLOUDLAB_CERT_PATH \
  -v `pwd`/geni/request.py:/request.py \
  -v `pwd`/vars.yml:/tmp/vars.yml \
  -v `pwd`/ansible/machines:/tmp/machines \
  --entrypoint=/request.py \
  ivotron/geni-lib:v0.9.4.6 --release
