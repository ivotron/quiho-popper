#!/bin/bash
set -e

echo '' > ansible/machines

docker pull ivotron/geni-lib:v0.9.4.6

if [ -z $CLOUDLAB_USER ]; then
  echo "Expecting CLOUDLAB_USER variable"
  exit 1
fi
if [ -z $CLOUDLAB_PASSWORD ]; then
  echo "Expecting CLOUDLAB_PASSWORD variable"
  exit 1
fi
if [ -z $CLOUDLAB_PROJECT ]; then
  echo "Expecting CLOUDLAB_PROJECT variable"
  exit 1
fi
if [ -z $CLOUDLAB_PUBKEY_PATH ]; then
  echo "Expecting CLOUDLAB_PUBKEY_PATH variable"
  exit 1
fi
if [ -z $CLOUDLAB_CERT_PATH ]; then
  echo "Expecting CLOUDLAB_CERT_PATH variable"
  exit 1
fi

docker run --rm \
  -e CLOUDLAB_USER=$CLOUDLAB_USER \
  -e CLOUDLAB_PASSWORD=$CLOUDLAB_PASSWORD \
  -e CLOUDLAB_PROJECT=$CLOUDLAB_PROJECT \
  -e CLOUDLAB_PUBKEY_PATH=$CLOUDLAB_PUBKEY_PATH \
  -e CLOUDLAB_CERT_PATH=$CLOUDLAB_CERT_PATH \
  -v $CLOUDLAB_PUBKEY_PATH:$CLOUDLAB_PUBKEY_PATH \
  -v $CLOUDLAB_CERT_PATH:$CLOUDLAB_CERT_PATH \
  -v `pwd`/geni/:/output \
  -v `pwd`/vars.yml:/vars.yml \
  --entrypoint=/output/request.py \
  ivotron/geni-lib:v0.9.4.6 --request

cp geni/machines ansible/
