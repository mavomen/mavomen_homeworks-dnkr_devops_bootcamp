#!/bin/bash
# Master builder: run every section in scratch, collect commands into git_commands_log.txt,
# then copy working files (without .git) into the tracked submission tree.
set -e
HW=/mnt/hdd/projects/0-shelfs/CodeStorage/06-DevOps_BOOTCAMP/homeworks/HW_L4_01_Git
SUB=$HW/ManiNava_git_01
SCRATCH=~/hw_l4_git_work/ManiNava_git_01
HW_LOG="$SUB/git_commands_log.txt"

rm -rf "$SCRATCH"
mkdir -p "$SCRATCH" "$HW/remotes"

export SCRATCH HW_LOG
: >"$HW_LOG"

for s in 01_basics 02_commits 03_branching 04_merging 05_stash 06_diff_history 07_reset_revert 08_github; do
  echo ">>> building $s"
  (cd "$SUB/$s" && bash build.sh)
done

# copy working trees into the tracked submission folder (no .git)
for s in 01_basics 02_commits 03_branching 04_merging 05_stash 06_diff_history 07_reset_revert 08_github; do
  for repo in "$SCRATCH/$s"/*; do
    [ -d "$repo" ] || continue
    base=$(basename "$repo")
    mkdir -p "$SUB/$s/$base"
    (cd "$repo" && find . -maxdepth 1 -name '.git' -prune -o -name '.' -o -print -exec sh -c 'cp -a "$1" "$2/ManiNava_git_01/'"$s"'/'"$base"'/."' _ {} "$HW" \;)
  done
  for f in "$SCRATCH/$s"/*.txt "$SCRATCH/$s"/*.md; do
    [ -f "$f" ] || continue
    cp -a "$f" "$SUB/$s/"
  done
done

cp "$HW_LOG" "$SUB/commands_history.txt"
echo "done"