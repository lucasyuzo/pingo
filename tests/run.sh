#!/usr/bin/env bash
# Runs every tests/test_*.sh under each available shell (bash, zsh and, on
# macOS, the system bash 3.2). Override with: SHELLS="bash zsh" tests/run.sh
set -u
case "$0" in */*) dir=${0%/*} ;; *) dir=. ;; esac
dir=$(CDPATH= cd -- "$dir" && pwd)

if [ -z "${SHELLS:-}" ]; then
  SHELLS="bash zsh"
  [ -x /bin/bash ] && [ "$(/bin/bash -c 'echo ${BASH_VERSINFO[0]}')" -lt 4 ] && SHELLS="$SHELLS /bin/bash"
fi

failed=0
ran=0
for sh in $SHELLS; do
  if ! command -v "$sh" >/dev/null 2>&1; then
    printf '\n## %s: not installed, skipping\n' "$sh"
    continue
  fi
  ver=$("$sh" -c 'printf %s "${ZSH_VERSION:-$BASH_VERSION}"')
  printf '\n## %s (%s)\n' "$sh" "$ver"
  for t in "$dir"/test_*.sh; do
    printf '%s\n' "- ${t##*/}"
    if ! T_DIR="$dir" "$sh" "$t"; then
      failed=$((failed + 1))
    fi
    ran=$((ran + 1))
  done
done

printf '\n'
if [ "$failed" -eq 0 ]; then
  printf 'All %s test runs passed.\n' "$ran"
else
  printf '%s of %s test runs FAILED.\n' "$failed" "$ran"
  exit 1
fi
