#!/bin/bash

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

archiveDirName() {
  local archive=$1

  if ! [[ "$archive" =~ (.*)".${SUFFIX}" ]]; then
    warn "${archive} does not match pattern"
    return 1
  fi

  echo "${BASH_REMATCH[1]}"
}

origDirName() {
  local archive=$1

  if ! [[ "$archive" =~ (.*)_(.*)".orig.${SUFFIX}" ]]; then
    warn "${archive} does not match pattern"
    return 1
  fi

  local name=${BASH_REMATCH[1]}
  local version=${BASH_REMATCH[2]}

  echo "${name}-${version}"
}

origNameFromChangelog() {
  local changelog=$1
  local tokens=($(head -1 "$changelog"))
  local name=${tokens[0]}
  local version=${tokens[1]:1:-1}
  ## Strip debian revision
  version=${version%-*}
  echo "${name}_${version}.orig.${SUFFIX}"
}

prepare() {
  checkNamerefs "$1" "$2" || return 1

  local -n _orig=$1
  local -n _dir=$2
  local _archive

  echo "Looking for upstream archive..."
  if _archive=$(findOne ".orig.${SUFFIX}"); then
    echo "Found orig archive ${_archive}"
    _dir=$(origDirName "$_archive")
    _orig=$_archive
  elif _archive=$(findOne ".${SUFFIX}"); then
    echo "Found archive ${_archive}"
    _dir=$(archiveDirName "$_archive")
  else
    echo "Upstream archive not found, abort."
    return 1
  fi

  if ! [ -d "$_dir" ]; then
    echo "Extracting archive"
    tar -xf "$_archive"
  fi

  if [ -d "debian" ] && ! [ -d "${_dir}/debian" ]; then
    echo "Copying debian directory"
    cp -r debian "$_dir"
  fi

  if ! [ "$_orig" ]; then
    _orig=$(origNameFromChangelog "${_dir}/debian/changelog")
    echo "Rename archive as ${_orig}"
    mv "$_archive" "$_orig"
  fi
}
