#!/bin/bash

NAME_PATTERN=${DEBPACKAGE:-'.*'}
SUFFIX='tar.gz'

warn() {
  echo 1>&2 "$@"
}

checkNamerefs() {
  local name
  for name; do
    if [[ "$name" = _* ]]; then
      warn "Nameref cannot start with underscore (${name})"
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

origDirName() {
  local archive=$1
  [[ "$archive" =~ ($NAME_PATTERN)_(.*)".orig.${SUFFIX}" ]] || return 1
  local name=${BASH_REMATCH[1]}
  local version=${BASH_REMATCH[2]}
  echo "${name}-${version}"
}

archiveDirName() {
  local archive=$1
  [[ "$archive" = *".${SUFFIX}" ]] || return 1
  echo "${archive%".${SUFFIX}"}"
}

ensureDebian() {
  local dir=$1

  if [ -d "${dir}/debian" ]; then
    return 0
  fi

  if [ -d "debian" ]; then
    echo "Copying debian directory from current directory"
    cp -a debian "$dir"
    return 0
  fi

  local archive
  if archive=$(findOne ".debian.${SUFFIX}"); then
    echo "Found debian archive, extracting..."
    tar --one-top-level -xf "$archive"

    local archiveDir=$(archiveDirName "$archive")
    local debdir=$(find "$archiveDir" -maxdepth 2 -type d -name "debian")
    if [ "$debdir" ]; then
      echo "Copying debian directory from archive"
      cp -a "$debdir" "$dir"
      return 0
    else
      warn "Cannot find debian directory in archive"
    fi
  fi

  return 1
}

prepare() {
  checkNamerefs "$1" "$2" || return 1

  local -n _arc=$1
  local -n _dir=$2

  echo "Looking for archive..."
  _arc=$(findOne ".orig.${SUFFIX}" || findOne ".${SUFFIX}") || {
    echo "Archive not found, abort."
    return 1
  }

  echo "Found archive ${_arc}"
  _dir=$(origDirName "$_arc" || archiveDirName "$_arc") || {
    echo "Cannot guess directory name from archive, abort."
    return 1
  }

  if ! [ -d "$_dir" ]; then
    echo "Extracting archive"
    tar -xf "$_arc"

    if ! [ -d "$_dir" ]; then
      echo "Archive does not contain expected directory ${_dir}, abort."
      return 1
    fi
  fi

  ensureDebian "$_dir" || {
    echo "Cannot find debian directory, abort."
    return 1
  }
}
