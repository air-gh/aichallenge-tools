#!/bin/bash -x

while true
do
    git pull
    bash autorun_server.sh -r ~ -i
    sleep 300
done
