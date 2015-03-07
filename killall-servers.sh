#!/bin/bash

tugboat droplets | grep ${CLUSTER_DOMAIN:-allthemusic.org} | awk '{ sub(/\)/, "", $9) }; { print $9 }' | xargs -n 1 tugboat destroy -c -i
