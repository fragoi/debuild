#!/bin/bash

SUFFIX="tar.gz"

warn() {
  echo 1>&2 "$@"
}

findOne() {
  local -n var=$1
  local suffix=$2
  local file=($(ls -d *${suffix} 2> /dev/null || true))
  if (( ${#file[@]} != 1 )); then
    warn "Found ${#file[@]} files (${suffix})"
    return 1
  fi
  var=$file
}

origName() {
  local -n var=$1
  local archive=$2

  ## name looks good already
  if [[ "$archive" =~ .*".orig.${SUFFIX}" ]]; then
    var="$archive"
    return 0
  fi

  if ! [[ "$archive" =~ (.*)-(.*)".${SUFFIX}" ]]; then
    warn "${archive} does not match pattern"
    return 1
  fi

  local name=${BASH_REMATCH[1]}
  local version=${BASH_REMATCH[2]}

  echo "Name: ${name}"
  echo "Version: ${version}"

  var="${name}_${version}.orig.${SUFFIX}"
}

dirName() {
  local -n var=$1
  local archive=$2

  if ! [[ "$archive" =~ (.*)_(.*)".orig.${SUFFIX}" ]]; then
    warn "${archive} does not match pattern"
    return 1
  fi

  local name=${BASH_REMATCH[1]}
  local version=${BASH_REMATCH[2]}

  var="${name}-${version}"
}

prepare() {
  local -n orig=$1
  local -n dir=$2

  echo "Looking for orig archive..."
  if ! findOne orig ".orig.${SUFFIX}"; then
    local archive

    echo "Orig archive not found, looking for upstream archive..."
    if ! findOne archive ".${SUFFIX}"; then
      echo "Upstream archive not found, abort."
      return 1
    fi

    echo "Found upstream archive ${archive}"
    origName orig "$archive"

    echo "Rename archive as ${orig}"
    mv "$archive" "$orig"
  fi

  echo "Found orig archive ${orig}"
  dirName dir "$orig"

  if ! [ -d "$dir" ]; then
    echo "Extracting orig archive"
    tar -xf "$orig"
  fi
}
