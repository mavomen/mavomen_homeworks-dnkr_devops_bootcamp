#!/bin/bash
# 1.1 - first playbook, variables & facts
# The three command variants from the assignment: plain run, syntax check and
# an extra-vars run that overrides the playbook values.
set -u
SCEN_DIR="$(cd "$(dirname "$0")" && pwd)"
SUBMIT="$(dirname "$SCEN_DIR")"
export ANSIBLE_CONFIG="$SUBMIT/ansible.cfg"
cd "$SCEN_DIR"

echo "--- 1.1a plain run ---"
ansible-playbook first_playbook.yml 2>&1 | tee first_playbook_run.txt

echo "--- 1.1b syntax check ---"
ansible-playbook first_playbook.yml --syntax-check 2>&1 | tee first_playbook_syntax_check.txt

echo "--- 1.1c extra vars win over playbook vars (-e) ---"
ansible-playbook first_playbook.yml -e "app_port=9090 app_version=2.0.0" 2>&1 | tee first_playbook_extra_vars.txt

{
    echo "=== /opt/MyApp/config.env written by the -e run (app_port must be 9090) ==="
    sudo cat /opt/MyApp/config.env
    echo
    echo "=== ls -l /opt/MyApp (created by the file task with become) ==="
    sudo ls -l /opt/MyApp
    echo
    echo "=== debug messages of the -e run: extra vars reached the Jinja2 templates ==="
    grep '"msg"' first_playbook_extra_vars.txt
    echo
    echo "=== the same messages in the plain run (playbook vars: app_port 8080 / version 1.0.0) ==="
    grep '"msg"' first_playbook_run.txt
} > config_env.txt 2>&1

echo "1.1 first_playbook completed. Reports: first_playbook_run.txt, first_playbook_syntax_check.txt, first_playbook_extra_vars.txt, config_env.txt"
