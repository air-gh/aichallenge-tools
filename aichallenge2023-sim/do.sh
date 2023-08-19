#!/bin/bash -x

while true
do
    git pull
    bash autorun_server.sh -r ~
    sleep 300
done
