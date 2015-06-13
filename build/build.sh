#!/bin/bash
set -e

DIR=$(realpath "$(dirname "$0")")

cd "$DIR"

ls build-*.sh | while read script; do
  ./$script
done
