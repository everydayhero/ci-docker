#!/bin/bash
set -e
source /build/buildconfig
set -x

BETA="true" DESTINATION=/buildkite bash -c "`curl -sL https://raw.githubusercontent.com/buildkite/agent/master/install.sh`"
