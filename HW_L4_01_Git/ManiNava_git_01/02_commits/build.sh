#!/bin/bash
# 02_commits - git add / git commit (2.1) and amending the last commit (2.2)
# shellcheck source=../lib/common.sh
source "$(dirname "$0")/../lib/common.sh"

SECTION="$SCRATCH/02_commits"
section 02_commits

: >"$SECTION/status_stages.txt"
: >"$SECTION/diff_outputs.txt"
: >"$SECTION/amend_log_before_after.txt"

# --- 2.1: working directory vs staging area vs repository ------------------
new_repo commit_demo

echo "Version 1" >file1.txt
echo "Version 1" >file2.txt
echo "Version 1" >file3.txt

g add file1.txt
{
  echo "## status: only file1.txt is staged"
  echo '$ git add file1.txt'
  echo '$ git status'
  g status
  echo
} >>"$SECTION/status_stages.txt"

g add file2.txt file3.txt
g commit -q -m "Initial commit with three files"

echo "Version 2" >>file1.txt
echo "Version 2" >>file2.txt

g add file1.txt
{
  echo "## status: file1.txt staged, file2.txt still modified"
  echo '$ git add file1.txt'
  echo '$ git status'
  g status
  echo
} >>"$SECTION/status_stages.txt"

# both diffs are captured while the staging area is non-empty, which is the
# only moment where --staged actually shows something
{
  echo "## unstaged changes (working directory vs staging area)"
  echo '$ git diff'
  g diff
  echo
  echo "## staged changes (staging area vs last commit)"
  echo '$ git diff --staged'
  g diff --staged
  echo
} >"$SECTION/diff_outputs.txt"

g commit -q -m "Update file1 to version 2"

# --- 2.2: amending the last commit -----------------------------------------
new_repo amend_demo

echo "Initial content" >document.txt
g add document.txt
g commit -q -m "Add document"

{
  echo "## log before amend"
  echo '$ git log --oneline'
  g log --oneline
  echo
} >"$SECTION/amend_log_before_after.txt"

echo "Config data" >config.txt
g add config.txt
g commit -q --amend -m "Add document and config file"
g commit -q --amend -m "Initial commit: Add document and config"

{
  echo "## log after amend (one commit, new message, extra file inside it)"
  echo '$ git commit --amend -m "Add document and config file"'
  echo '$ git commit --amend -m "Initial commit: Add document and config"'
  echo '$ git log --oneline'
  g log --oneline
  echo
  echo "## the single commit now contains both files"
  echo '$ git show --stat --oneline HEAD'
  g show --stat --oneline HEAD
  echo
} >>"$SECTION/amend_log_before_after.txt"
