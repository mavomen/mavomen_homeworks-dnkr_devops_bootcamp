#!/bin/bash
# 1.2 - loops and conditionals
# One real run plus a second run, because the interesting part of this
# playbook is what the `when` conditions do on the second pass.
set -u
SCEN_DIR="$(cd "$(dirname "$0")" && pwd)"
SUBMIT="$(dirname "$SCEN_DIR")"
export ANSIBLE_CONFIG="$SUBMIT/ansible.cfg"
cd "$SCEN_DIR"

echo "--- 1.2a first run (stat says the directory does not exist yet) ---"
ansible-playbook conditionals_loops.yml 2>&1 | tee conditionals_loops_run.txt

echo "--- 1.2b second run (the create task is now skipped by its condition) ---"
ansible-playbook conditionals_loops.yml 2>&1 | tee conditionals_loops_rerun.txt

{
    echo "=== users created by the loop over the users list ==="
    getent passwd user1 user2
    echo
    echo "=== /opt/myapp created by the stat/when pair ==="
    sudo ls -ld /opt/myapp
    echo
    echo "=== curl/wget/git on this box, so the Debian-only apt loop was skipped ==="
    pacman -Q curl wget git 2>&1
    echo
    echo "=== skipped lines of the first run (3 apt items + create-if-not-exists + ubuntu-only) ==="
    grep -n "skipping" conditionals_loops_run.txt
    echo
    echo "=== and of the second run, where 'Create if not exists' is skipped as well ==="
    grep -n "skipping" conditionals_loops_rerun.txt
} > conditionals_loops_evidence.txt 2>&1

echo "1.2 conditionals_loops completed. Reports: conditionals_loops_run.txt, conditionals_loops_rerun.txt, conditionals_loops_evidence.txt"
