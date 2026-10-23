#!/bin/bash
# Shared helpers for the Git homework builders.
# Every build.sh sources this file; it is not meant to be run on it's own.

: "${SCRATCH:?SCRATCH must point at the scratch work tree}"
: "${HW_LOG:?HW_LOG must point at git_commands_log.txt}"

# move into a section of the scratch tree
section() {
  mkdir -p "$SCRATCH/$1"
  cd "$SCRATCH/$1" || exit 1
}

# run a git command: execute it and log the exact command line globally
g() {
  printf 'git %s\n' "$*" >>"$HW_LOG"
  git "$@"
}

# run a git command, log it globally, and append "command + output" to an output file
gc() { # gc <file> <label> <git args...>
  local file="$1" label="$2"
  shift 2
  {
    printf '## %s\n' "$label"
    printf '$ git %s\n' "$*"
    git "$@" 2>&1
    printf '\n'
  } >>"$file"
  printf 'git %s\n' "$*" >>"$HW_LOG"
}

# run any command and append "command + output" to an output file
c() { # c <file> <label> <command...>
  local file="$1" label="$2"
  shift 2
  {
    printf '## %s\n' "$label"
    printf '$ %s\n' "$*"
    "$@" 2>&1
    printf '\n'
  } >>"$file"
}

# make a repo-local identity so the evidence does not depend on the global config
local_identity() {
  git config user.name "ManiNava"
  git config user.email "manihabibinava@gmail.com"
}

# start a fresh repository in a sub-directory of the current section
new_repo() { # new_repo <dir>
  rm -rf "$1"
  mkdir -p "$1"
  cd "$1" || exit 1
  g init -q
  local_identity
}
