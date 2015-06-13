#!/bin/bash
set -e
source /build/buildconfig
set -x

declare -a vars=(
  AWS_ACCESS_KEY_ID
  AWS_DEFAULT_REGION
  AWS_SECRET_ACCESS_KEY
  CONSUL_URL
  DOCKER_EMAIL
  DOCKER_PASSWORD
  DOCKER_SERVER
  DOCKER_USERNAME
  EC2_VPC
  PLAIN_HOSTNAME
  PLAIN_HOST_IP
  PLAIN_STATSD_HOST
  SSH_BASTION_USER
  SSH_USER
)

packages="
  python
  rsync
"

curl https://circle-artifacts.com/gh/gliderlabs/glidergun/47/artifacts/0/tmp/circle-artifacts.Rnr25Ip/gun-linux.tgz | tar -zxC /usr/local/bin

$minimal_apt_get_install $packages

for var in "${vars[@]}"; do
  export $var=lol
done

plain-gun

for var in "${vars[@]}"; do
  unset $var
done
