#!/bin/bash -e

. archive.sh

prepare orig dir

echo "Changing directory ${dir}"
cd "$dir"

echo "Run debsign"
debsign "$@"
