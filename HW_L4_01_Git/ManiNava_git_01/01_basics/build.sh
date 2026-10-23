#!/bin/bash
# 01_basics - installation/introduction (1.1) and the first repository (1.2)
# shellcheck source=../lib/common.sh
source "$(dirname "$0")/../lib/common.sh"

section 01_basics

# --- 1.1: configuration, captured before any repository exists -------------
{
  echo "## Installed version"
  echo '$ git --version'
  git --version
  echo
  echo "## git config --list"
  echo '$ git config --list'
  git config --list
  echo
  echo "## identity"
  echo '$ git config user.name'
  git config user.name
  echo '$ git config user.email'
  git config user.email
} >config_output.txt

printf 'git --version\ngit config --list\ngit config user.name\ngit config user.email\n' >>"$HW_LOG"

# --- 1.2: first repository and the first two commits ----------------------
: >status_after_add.txt
new_repo my_project

echo "# My Project" >README.md
echo "console.log('Hello World');" >app.js
echo "body { color: blue; }" >style.css

g add README.md
{
  echo "## status after staging README.md only"
  echo '$ git add README.md'
  echo '$ git status'
  g status
  echo
} >>status_after_add.txt

g commit -q -m "Add README file"

g add app.js style.css
g commit -q -m "Add application files"

{
  echo "## history"
  echo '$ git log --oneline'
  g log --oneline
  echo
} >log_oneline.txt
