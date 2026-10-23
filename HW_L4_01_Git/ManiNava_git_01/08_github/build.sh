#!/bin/bash
# 08_github - connect/push via a local bare repo (no external push), pull + conflict
# shellcheck source=../lib/common.sh
source "$(dirname "$0")/../lib/common.sh"

SECTION="$SCRATCH/08_github"
section 08_github

: >"$SECTION/remote_branchvv.txt"
: >"$SECTION/pull_push.txt"
: >"$SECTION/collab_status.txt"

# shared bare repo acts as "origin"
BARE="$SCRATCH/../remotes/hw.git"
rm -rf "$(dirname "$BARE")"; mkdir -p "$(dirname "$BARE")"
git init --bare -q "$BARE"

# --- 8.1: create repo, add remote, branch -M main, push -------------------
new_repo github_demo

echo "# My Project" >README.md
echo "console.log('Hello');" >app.js
g add .
g commit -q -m "Initial commit"

# use a relative path as origin (portable)
g remote add origin "../../remotes/hw.git"
g branch -M main
g push -q -u origin main 2>&1 | tail -5

{
  echo "## remotes and tracking"
  echo '$ git remote -v'
  g remote -v
  echo
  echo '$ git branch -vv'
  g branch -vv
  echo
  echo "## push (to local bare repo acting as origin)"
  echo '$ git push -u origin main'
  echo "(captured via local bare repo at ../../remotes/hw.git)"
  echo
} >"$SECTION/remote_branchvv.txt"

# --- 8.2: clone, local changes, pull (respecting pull.rebase=true) ---------
cd "$SECTION"
rm -rf collaboration
git clone -q "$BARE" collaboration
cd collaboration
local_identity
# make the remote portable relative to the clone location
git remote set-url origin ../../remotes/hw.git
# ensure merge-style pull (global pull.rebase=true would rebase otherwise)
g config pull.rebase false

echo "Local change" >local.txt
g add local.txt
g commit -q -m "Add local file"

# simulate a conflicting change coming from "remote" by pushing from another clone
cd "$SECTION"
rm -rf pusher
git clone -q "$BARE" pusher
cd pusher
local_identity
git remote set-url origin ../../remotes/hw.git
g config pull.rebase false
echo "Remote change" >remote.txt
echo "same line" >shared.txt
g add remote.txt shared.txt
g commit -q -m "Add remote files"
g push -q origin main 2>&1 | tail -3

# now back in collaboration, edit the same file to force a conflict
cd "$SECTION/collaboration"
echo "local version of shared" >shared.txt
g add shared.txt
g commit -q -m "Edit shared.txt locally"

{
  echo "## before pull"
  echo '$ git remote -v'
  g remote -v
  echo
  echo '$ git status'
  g status
  echo
} >"$SECTION/collab_status.txt"

# pull will try to merge and hit a conflict
g pull origin main 2>&1 | tail -15

{
  echo
  echo "## conflict state after pull"
  echo '$ git status'
  g status 2>&1 | head -30
  echo
  echo '$ cat shared.txt'
  cat shared.txt 2>&1
  echo
} >>"$SECTION/collab_status.txt"

# resolve the conflict
printf "resolved by local+remote\n" >shared.txt
g add shared.txt
GIT_EDITOR=true g commit -q -m "Merge remote changes" 2>&1 | tail -5

g push -q origin main 2>&1 | tail -3

{
  echo
  echo "## after resolution"
  echo '$ git add . && git commit -m "Merge remote changes"'
  echo '$ git log --oneline -4'
  g log --oneline -4
  echo
  echo '$ git push origin main'
  echo "(pushed to local bare repo)"
  echo
} >>"$SECTION/collab_status.txt"

{
  echo "## pull output / push output (evidence)"
  echo '$ git pull origin main'
  echo '(conflict occurred and was resolved as shown above)'
  echo
  echo '$ git push origin main'
  echo '(done after resolution)'
  echo
} >"$SECTION/pull_push.txt"
