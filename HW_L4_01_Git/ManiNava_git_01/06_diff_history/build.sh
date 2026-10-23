#!/bin/bash
# 06_diff_history - git diff variants (6.1) and time travel / detached HEAD (6.2)
# shellcheck source=../lib/common.sh
source "$(dirname "$0")/../lib/common.sh"

SECTION="$SCRATCH/06_diff_history"
section 06_diff_history

: >"$SECTION/diff_types.txt"
: >"$SECTION/detached_head.txt"

# --- 6.1: git diff, diff --staged, diff HEAD, diff between branches/commits ---
new_repo diff_demo

echo "Line 1" >file1.txt
echo "Line 1" >file2.txt
g add file1.txt file2.txt
g commit -q -m "Initial commit"

echo "Line 2" >>file1.txt
echo "Line 2" >>file2.txt
g add file1.txt

{
  echo "## git diff (unstaged only: file2.txt)"
  echo '$ git diff'
  g diff
  echo
  echo "## git diff --staged (staged only: file1.txt)"
  echo '$ git diff --staged'
  g diff --staged
  echo
  echo "## git diff HEAD (all changes vs last commit)"
  echo '$ git diff HEAD'
  g diff HEAD
  echo
  echo "## filter by file"
  echo '$ git diff file1.txt'
  g diff file1.txt
  echo
  echo '$ git diff --staged file2.txt'
  g diff --staged file2.txt
  echo
} >"$SECTION/diff_types.txt"

g branch feature
g switch feature >/dev/null 2>&1 || g checkout feature >/dev/null 2>&1
echo "Feature line" >>file1.txt
g add file1.txt
g commit -q -m "Feature change"
g switch main >/dev/null 2>&1 || g checkout main >/dev/null 2>&1

{
  echo "## diff between branches"
  echo '$ git diff main feature'
  g diff main feature
  echo
  echo '$ git diff main feature -- file1.txt'
  g diff main feature -- file1.txt
  echo
  echo "## diff between commits"
  echo '$ git log --oneline'
  g log --oneline
  echo
  echo '$ git diff HEAD~1 HEAD'
  g diff HEAD~1 HEAD
  echo
} >>"$SECTION/diff_types.txt"

# --- 6.2: time travel with detached HEAD -----------------------------------
new_repo time_travel

echo "Commit 1" >file.txt
g add file.txt
g commit -q -m "Commit 1"
echo "Commit 2" >>file.txt
g add file.txt
g commit -q -m "Commit 2"
echo "Commit 3" >>file.txt
g add file.txt
g commit -q -m "Commit 3"

{
  echo "## history"
  echo '$ git log --oneline'
  g log --oneline
  echo
  echo "## enter detached HEAD at HEAD~1"
  echo '$ git checkout HEAD~1'
  g checkout HEAD~1 2>&1 | tail -6
  echo
  echo '$ git status'
  g status
  echo
  echo '$ git log --oneline'
  g log --oneline
  echo
  echo "## create a branch from detached HEAD to save work"
  echo '$ git branch from-detached'
  g branch from-detached
  echo
  echo "## return to main"
  echo '$ git switch main'
  g switch main 2>&1 | tail -4
  echo
  echo "## relative refs"
  echo '$ git checkout HEAD~2'
  g checkout HEAD~2 2>&1 | tail -3
  echo '$ git checkout HEAD^'
  g checkout HEAD^ 2>&1 | tail -3
  echo '$ git switch main'
  g switch main 2>&1 | tail -2
  echo
} >"$SECTION/detached_head.txt"
