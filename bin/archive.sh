#!/bin/bash

NAME_PATTERN=${DEBPACKAGE:-.*}
SUFFIX="tar.gz"

warn() {
  echo 1>&2 "$@"
}

checkNamerefs() {
  local name
  for name in "$@"; do
    if [[ "$name" = _* ]]; then
      warn "Nameref cannot start with underscore ($1)"
      return 1
    fi
  done
}

findOne() {
  local suffix=$1
  local file=($(ls -d *${suffix} 2> /dev/null || true))
  if (( ${#file[@]} != 1 )); then
    warn "Found ${#file[@]} files (${suffix})"
    return 1
  fi
  echo $file
}

origName() {
  local archive=$1

  ## name looks good already
  if [[ "$archive" =~ .*".orig.${SUFFIX}" ]]; then
    echo "$archive"
    return 0
  fi

  if ! [[ "$archive" =~ ($NAME_PATTERN)-(.*)".${SUFFIX}" ]]; then
    warn "${archive} does not match pattern"
    return 1
  fi

  local name=${BASH_REMATCH[1]}
  local version=${BASH_REMATCH[2]}

  echo "${name}_${version}.orig.${SUFFIX}"
}

dirName() {
  local archive=$1

  if ! [[ "$archive" =~ ($NAME_PATTERN)_(.*)".orig.${SUFFIX}" ]]; then
    warn "${archive} does not match pattern"
    return 1
  fi

  local name=${BASH_REMATCH[1]}
  local version=${BASH_REMATCH[2]}

  echo "${name}-${version}"
}

prepare() {
  checkNamerefs "$1" "$2" || return 1

  local -n _orig=$1
  local -n _dir=$2

  echo "Looking for orig archive..."
  if ! _orig=$(findOne ".orig.${SUFFIX}"); then
    local _archive

    echo "Orig archive not found, looking for upstream archive..."
    if ! _archive=$(findOne ".${SUFFIX}"); then
      echo "Upstream archive not found, abort."
      return 1
    fi

    echo "Found upstream archive ${_archive}"
    _orig=$(origName "$_archive")

    echo "Rename archive as ${_orig}"
    mv "$_archive" "$_orig"
  fi

  echo "Found orig archive ${_orig}"
  _dir=$(dirName "$_orig")

  if ! [ -d "$_dir" ]; then
    echo "Extracting orig archive"
    tar -xf "$_orig"
  fi

  if [ -d "debian" ] && ! [ -d "${_dir}/debian" ]; then
    echo "Copying debian directory"
    cp -r debian "$_dir"
  fi
}
