#!/bin/bash

docker run -d \
  --name jupyter_`basename $PWD` \
  -p 8888:8888 \
  -v `pwd`:/home/jovyan/work ivotron/scipy-notebook \
  start-notebook.sh --NotebookApp.token=""
