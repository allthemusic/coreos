#!/bin/bash

tugboat droplets | grep allthemusic.org | grep -oE '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | xargs -n1 ssh-keygen -R
