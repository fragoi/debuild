#!/bin/bash -e

. archive.sh

prepare orig dir

echo "Changing directory ${dir}"
cd "$dir"

echo "Installing dependencies"
install-deps.sh "debian/control"
install-deps.sh "debian/control" "-Arch"
install-deps.sh "debian/control" "-Indep"

echo "Run debuild"
debuild "$@"
