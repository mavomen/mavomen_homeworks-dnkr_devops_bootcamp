#!/bin/bash
# 07_reset_revert - reset (soft/mixed/hard) with git restore (7.1) and git revert (7.2)
# shellcheck source=../lib/common.sh
source "$(dirname "$0")/../lib/common.sh"

SECTION="$SCRATCH/07_reset_revert"
section 07_reset_revert

: >"$SECTION/reset_log_status.txt"
: >"$SECTION/revert_log.txt"

# --- 7.1: git restore and git reset -----------------------------------------
new_repo reset_demo

echo "Version 1" >file.txt
g add file.txt
g commit -q -m "Commit 1"
echo "Version 2" >file.txt
g add file.txt
g commit -q -m "Commit 2"
echo "Version 3" >file.txt
g add file.txt
g commit -q -m "Commit 3"

{
  echo "## initial history"
  echo '$ git log --oneline'
  g log --oneline
  echo
} >"$SECTION/reset_log_status.txt"

echo "Modified" >file.txt
g add file.txt
g restore --staged file.txt 2>&1 | tail -2
{
  echo "## restore --staged: unstage"
  echo '$ echo "Modified" > file.txt'
  echo '$ git add file.txt'
  echo '$ git restore --staged file.txt'
  echo '$ git status --short'
  g status --short
  echo
} >>"$SECTION/reset_log_status.txt"

g restore file.txt 2>&1 | tail -2
{
  echo "## restore: discard changes in working tree"
  echo '$ git restore file.txt'
  echo '$ git status --short'
  g status --short
  echo
} >>"$SECTION/reset_log_status.txt"

# rebuild to a clean state for the reset trilogy
new_repo reset_demo2
echo "Version 1" >file.txt; g add file.txt; g commit -q -m "Commit 1"
echo "Version 2" >file.txt; g add file.txt; g commit -q -m "Commit 2"
echo "Version 3" >file.txt; g add file.txt; g commit -q -m "Commit 3"

{
  echo "## reset --soft HEAD~1 (moves HEAD only)"
  echo '$ git log --oneline'
  g log --oneline
  echo '$ git reset --soft HEAD~1'
  g reset --soft HEAD~1
  echo '$ git log --oneline'
  g log --oneline
  echo '$ git status'
  g status
  echo
} >>"$SECTION/reset_log_status.txt"

new_repo reset_demo3
echo "Version 1" >file.txt; g add file.txt; g commit -q -m "Commit 1"
echo "Version 2" >file.txt; g add file.txt; g commit -q -m "Commit 2"
echo "Version 3" >file.txt; g add file.txt; g commit -q -m "Commit 3"

{
  echo "## reset (mixed, default) HEAD~1 (moves HEAD and staging)"
  echo '$ git log --oneline'
  g log --oneline
  echo '$ git reset HEAD~1'
  g reset HEAD~1
  echo '$ git log --oneline'
  g log --oneline
  echo '$ git status'
  g status
  echo
} >>"$SECTION/reset_log_status.txt"

new_repo reset_demo4
echo "Version 1" >file.txt; g add file.txt; g commit -q -m "Commit 1"
echo "Version 2" >file.txt; g add file.txt; g commit -q -m "Commit 2"
echo "Version 3" >file.txt; g add file.txt; g commit -q -m "Commit 3"

{
  echo "## reset --hard HEAD~1 (moves HEAD, staging, and working tree)"
  echo '$ git log --oneline'
  g log --oneline
  echo '$ git reset --hard HEAD~1'
  g reset --hard HEAD~1
  echo '$ git log --oneline'
  g log --oneline
  echo '$ git status'
  g status
  echo
} >>"$SECTION/reset_log_status.txt"

# --- 7.2: git revert --------------------------------------------------------
new_repo revert_demo

echo "Line 1" >file.txt
g add file.txt
g commit -q -m "Add line 1"
echo "Line 2" >>file.txt
g add file.txt
g commit -q -m "Add line 2"
echo "Line 3" >>file.txt
g add file.txt
g commit -q -m "Add line 3"

{
  echo "## history before revert"
  echo '$ git log --oneline'
  g log --oneline
  echo
  echo "## revert last commit"
  echo '$ git revert HEAD  (auto-commit)'
  GIT_EDITOR=true g revert -q HEAD 2>&1 || GIT_EDITOR=true g revert HEAD
  echo '$ git log --oneline'
  g log --oneline
  echo
  echo "## revert a specific (older) commit"
  echo '$ git revert HEAD~1'
  GIT_EDITOR=true g revert -q HEAD~1 2>&1 || GIT_EDITOR=true g revert HEAD~1
  echo '$ git log --oneline'
  g log --oneline
  echo
  echo "## show the most recent revert commit"
  echo '$ git show HEAD'
  g show HEAD
  echo
} >"$SECTION/revert_log.txt"
