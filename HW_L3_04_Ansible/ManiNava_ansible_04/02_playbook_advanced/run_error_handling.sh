#!/bin/bash
# 2.2 - error handling patterns
# ignore_errors, failed_when, changed_when and block/rescue/always. The
# assert task really fails on this box (Arch is not Ubuntu/Debian) and that
# failure is part of the evidence.
set -u
SCEN_DIR="$(cd "$(dirname "$0")" && pwd)"
SUBMIT="$(dirname "$SCEN_DIR")"
export ANSIBLE_CONFIG="$SUBMIT/ansible.cfg"
cd "$SCEN_DIR"

echo "--- 2.2 error handling run ---"
ansible-playbook error_handling.yml 2>&1 | tee error_handling_run.txt

{
    echo "=== every task line with its result (Gathering Facts first) ==="
    grep -E "^(TASK |changed:|ok:|fatal:|failed:|skipped:)" error_handling_run.txt
    echo
    echo "=== the ignored failure (command /bin/false with ignore_errors) ==="
    grep -n -A2 "Task that fails but ignored" error_handling_run.txt | head -12
    echo
    echo "=== the assert failure with its fail_msg ==="
    grep -n -A6 "Assert requirements" error_handling_run.txt | head -14
    echo
    echo "=== rescue / always lines ==="
    grep -n -E "Error handled gracefully|Always executed" error_handling_run.txt
    echo
    echo "=== play recap ==="
    grep -n -E "failed=|ignored=|changed=|ok=" error_handling_run.txt | tail -3
} > error_handling_evidence.txt 2>&1

echo "2.2 error_handling completed. Reports: error_handling_run.txt, error_handling_evidence.txt"
