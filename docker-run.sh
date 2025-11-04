#!/bin/bash

docker build -t syscheck .

#--entrypoint "/bin/bash" \

docker run -it \
    --entrypoint "/bin/bash" \
    --mount type=bind,source=$PWD/results,target=/results \
    --mount type=bind,source=$PWD/,target=/opt/syscheck \
    syscheck
