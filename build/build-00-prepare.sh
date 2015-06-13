#!/bin/bash
set -e
source /build/buildconfig
set -x

## Temporarily disable dpkg fsync to make building faster.
if [[ ! -e /etc/dpkg/dpkg.cfg.d/docker-apt-speedup ]]; then
  echo force-unsafe-io > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup
fi

## Use cloudfront debian mirror
sed -i -e 's,httpredir.debian.org,cloudfront.debian.net,' /etc/apt/sources.list
apt-get update

## Install HTTPS support for APT.
$minimal_apt_get_install apt-transport-https ca-certificates

# Install debconf utils
$minimal_apt_get_install debconf-utils

## Upgrade all packages.
apt-get dist-upgrade -y --no-install-recommends

cat <<EOF | debconf-set-selections
locales locales/default_environment_locale  select  en_US.UTF-8
locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8
EOF

$minimal_apt_get_install locales
