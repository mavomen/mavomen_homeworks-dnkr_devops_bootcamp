#!/bin/bash
# 03_branching - creating/switching branches (3.1) and managing them (3.2)
# shellcheck source=../lib/common.sh
source "$(dirname "$0")/../lib/common.sh"

SECTION="$SCRATCH/03_branching"
section 03_branching

: >"$SECTION/branch_log_graph.txt"
: >"$SECTION/branch_mgmt.txt"

# --- 3.1: branches, HEAD, switching (checkout/switch) ----------------------
new_repo branch_demo

echo "Main content" >main.txt
g add main.txt
g commit -q -m "Initial commit on main"

g branch feature-login
g branch
g checkout feature-login >/dev/null 2>&1 || true
g switch feature-login >/dev/null 2>&1

echo "Login feature" >login.js
g add login.js
g commit -q -m "Add login feature"

g switch main >/dev/null 2>&1 || g checkout main >/dev/null 2>&1

{
  echo "## branches and graph (main vs feature-login)"
  echo '$ git branch'
  g branch
  echo
  echo '$ git log --oneline --graph --all'
  g log --oneline --graph --all
  echo
  echo "## note: both git checkout and git switch demonstrated"
  echo '$ git checkout feature-login  (shown)'
  echo '$ git switch feature-login   (shown)'
  echo
} >"$SECTION/branch_log_graph.txt"

# --- 3.2: rename, delete, moving between branches --------------------------
new_repo branch_management

echo "Content" >file.txt
g add file.txt
g commit -q -m "Initial commit"

g branch feature-a
g branch feature-b
g branch old-feature

g branch -m old-feature new-feature

g switch main >/dev/null 2>&1 || g checkout main >/dev/null 2>&1
g branch -d feature-a 2>&1 || true
g branch -D feature-b 2>&1 || true

g switch new-feature >/dev/null 2>&1 || g checkout new-feature >/dev/null 2>&1
echo "New content" >new.txt
g add new.txt

g switch main >/dev/null 2>&1 || g checkout main >/dev/null 2>&1
g status

g switch new-feature >/dev/null 2>&1 || g checkout new-feature >/dev/null 2>&1
g commit -q -m "Add new file"

{
  echo "## branch list across operations"
  echo '$ git branch'
  g branch
  echo
  echo '$ git branch -a'
  g branch -a
  echo
  echo "## rename, delete (-d vs -D), and switching"
  echo '$ git branch -m old-feature new-feature'
  echo '$ git switch main'
  echo '$ git branch -d feature-a'
  echo '$ git branch -D feature-b'
  echo '$ git switch new-feature'
  echo '$ git switch main  (with uncommitted change: new.txt staged context shown by status)'
  echo '$ git status'
  g status 2>&1 | tail -20
  echo
} >"$SECTION/branch_mgmt.txt"
