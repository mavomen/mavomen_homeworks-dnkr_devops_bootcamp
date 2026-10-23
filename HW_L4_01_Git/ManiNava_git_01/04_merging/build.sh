#!/bin/bash
# 04_merging - fast-forward, three-way merge with no conflict, and conflict resolution
# shellcheck source=../lib/common.sh
source "$(dirname "$0")/../lib/common.sh"

SECTION="$SCRATCH/04_merging"
section 04_merging

: >"$SECTION/ff_merge_log.txt"
: >"$SECTION/no_conflict_log.txt"
: >"$SECTION/conflict_before_after.txt"

# --- 4.1: fast-forward merge -----------------------------------------------
new_repo ff_merge

echo "Main file" >main.txt
g add main.txt
g commit -q -m "Initial commit"

g branch feature
g switch feature >/dev/null 2>&1 || g checkout feature >/dev/null 2>&1
echo "Feature file" >feature.txt
g add feature.txt
g commit -q -m "Add feature"

g switch main >/dev/null 2>&1 || g checkout main >/dev/null 2>&1
g merge feature -q

{
  echo "## fast-forward merge"
  echo '$ git merge feature'
  echo '$ git log --oneline --graph'
  g log --oneline --graph
  echo
} >"$SECTION/ff_merge_log.txt"

# --- 4.2: merge with no conflict (files created on different branches) -----
new_repo no_conflict

echo "Base" >base.txt
g add base.txt
g commit -q -m "Base commit"

g branch branch-a
g switch branch-a >/dev/null 2>&1 || g checkout branch-a >/dev/null 2>&1
echo "File A" >file_a.txt
g add file_a.txt
g commit -q -m "Add file A"

g switch main >/dev/null 2>&1 || g checkout main >/dev/null 2>&1
g branch branch-b
g switch branch-b >/dev/null 2>&1 || g checkout branch-b >/dev/null 2>&1
echo "File B" >file_b.txt
g add file_b.txt
g commit -q -m "Add file B"

g switch main >/dev/null 2>&1 || g checkout main >/dev/null 2>&1
g merge branch-a -q
g merge branch-b -q

{
  echo "## merge commit (no conflict) - two branches merged in"
  echo '$ git merge branch-a'
  echo '$ git merge branch-b'
  echo '$ git log --oneline --graph --all'
  g log --oneline --graph --all
  echo
} >"$SECTION/no_conflict_log.txt"

# --- 4.3: conflict creation and resolution ---------------------------------
new_repo conflict_demo

echo "Line 1" >conflict.txt
g add conflict.txt
g commit -q -m "Initial commit"

g branch branch-a
g switch branch-a >/dev/null 2>&1 || g checkout branch-a >/dev/null 2>&1
printf "Line 1\nLine 2 from A\n" >conflict.txt
g add conflict.txt
g commit -q -m "Add line from A"

g switch main >/dev/null 2>&1 || g checkout main >/dev/null 2>&1
g branch branch-b
g switch branch-b >/dev/null 2>&1 || g checkout branch-b >/dev/null 2>&1
printf "Line 1\nLine 2 from B\n" >conflict.txt
g add conflict.txt
g commit -q -m "Add line from B"

g switch main >/dev/null 2>&1 || g checkout main >/dev/null 2>&1
{
  echo "## before conflict resolution"
  echo '$ git merge branch-a'
  g merge branch-a -q 2>&1 || true
  echo '$ git merge branch-b  # conflict!'
  git merge branch-b 2>&1 || true
  echo
  echo '$ cat conflict.txt'
  cat conflict.txt 2>&1
  echo
} >"$SECTION/conflict_before_after.txt"

# resolve by taking both lines in a deterministic way (documented)
printf "Line 1\nLine 2 from A\nLine 2 from B\n" >conflict.txt
g add conflict.txt
GIT_EDITOR=true g commit -q -m "Merge branch-b, resolve conflict"

{
  echo
  echo "## after conflict resolution"
  echo '$ cat conflict.txt'
  cat conflict.txt
  echo
  echo '$ git log --oneline --graph --all'
  g log --oneline --graph --all
  echo
} >>"$SECTION/conflict_before_after.txt"
