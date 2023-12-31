#!/bin/bash -x

while true
do
    git pull
    bash autorun_server.sh
    sleep 10
done
