#!/bin/bash -e

readline() {
  IFS='' read "$@"
}

field=$1

begin_line="^${field}[[:space:]]*:.*"
comment_line="^[[:space:]]*#.*"
end_line="^[[:graph:]].*"

while readline line; do
  if [[ "$line" =~ $begin_line ]]; then
    echo "${line#*:}"
    while readline line; do
      ## skip blank lines and comments
      if [ -z "$line" ] || [[ "$line" =~ $comment_line ]]; then
        continue
      fi
      ## any other tag terminate the value
      if [[ "$line" =~ $end_line ]]; then
        break
      fi
      echo "$line"
    done
    break
  fi
done
