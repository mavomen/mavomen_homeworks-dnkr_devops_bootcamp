#!/bin/bash
# 05_stash - stash, stash push with messages, list/show/apply/pop/drop/clear
# shellcheck source=../lib/common.sh
source "$(dirname "$0")/../lib/common.sh"

SECTION="$SCRATCH/05_stash"
section 05_stash

: >"$SECTION/stash_list_show.txt"

new_repo stash_demo

echo "Initial" >file.txt
g add file.txt
g commit -q -m "Initial commit"

echo "Change 1" >>file.txt
echo "New file" >new.txt

g stash push -q -u -m "WIP: working on feature" 2>&1 || g stash push -q -m "WIP: working on feature"
g status --short

echo "Change 2" >>file.txt
g stash push -q -m "Another WIP"

{
  echo "## stash list"
  echo '$ git stash list'
  g stash list
  echo
  echo "## stash show"
  echo '$ git stash show'
  g stash show
  echo
  echo '$ git stash show -p'
  g stash show -p
  echo
  echo '$ git stash show stash@{1}'
  g stash show stash@{1}
  echo
  echo "## apply (without dropping) and pop"
  echo '$ git stash apply'
  g stash apply 2>&1 | tail -10
  echo
  echo '$ git stash pop'
  g stash pop 2>&1 | tail -10
  echo
  echo '$ git stash list (after pop/apply scenario)'
  g stash list
  echo
} >"$SECTION/stash_list_show.txt"

# clean slate to demonstrate drop/clear explicitly
new_repo stash_demo2
echo "Initial" >file.txt
g add file.txt
g commit -q -m "Initial commit"
echo "x" >>file.txt
g stash push -q -m "tmp1"
echo "y" >>file.txt
g stash push -q -m "tmp2"
g stash list
g stash drop stash@{0} >/dev/null 2>&1
g stash clear >/dev/null 2>&1
g stash list
printenv > /dev/null
