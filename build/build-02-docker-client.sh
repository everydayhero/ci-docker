#!/bin/bash
set -e
source /build/buildconfig
set -x

docker_version=1.5.0

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9

echo "deb https://get.docker.io/ubuntu docker main" > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y lxc-docker-$docker_version
