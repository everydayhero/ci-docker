#!/bin/bash
set -e
source /build/buildconfig
set -x

PACKAGES="
  wget
  perl
  openssh-client
  curl
  git-core
  unzip
"

$minimal_apt_get_install $PACKAGES
