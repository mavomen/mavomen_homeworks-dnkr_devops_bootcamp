#!/bin/bash
# 4.1 - roles
# deploy.yml runs three roles (common, webserver, monitoring - and monitoring
# pulls common in through its meta/main.yml dependency), then a second play
# shows include_role with a condition and with custom vars.
set -u
SCEN_DIR="$(cd "$(dirname "$0")" && pwd)"
SUBMIT="$(dirname "$SCEN_DIR")"
export ANSIBLE_CONFIG="$SUBMIT/ansible.cfg"
cd "$SCEN_DIR"

sudo mkdir -p /var/www/html /opt/logs /opt/apps /opt/scripts

{
    echo "=== role skeletons created with ansible-galaxy init ==="
    find roles -type f | sort
} > roles_tree.txt

echo "--- 4.1a full deploy (both plays) ---"
ansible-playbook deploy.yml 2>&1 | tee roles_run.txt

echo "--- 4.1b only the monitoring role, by tag (its 'common' dependency comes with it) ---"
ansible-playbook deploy.yml --tags monitoring 2>&1 | tee roles_tags_monitoring.txt

{
    echo "=== rendered /var/www/html/index.html (webserver_port 8080 came from deploy.yml vars) ==="
    sudo cat /var/www/html/index.html
    echo
    echo "=== /opt/scripts/monitor.sh from the monitoring role ==="
    sudo cat /opt/scripts/monitor.sh
    echo
    echo "=== /opt/logs/deploy.log from deploy.yml post_tasks ==="
    sudo cat /opt/logs/deploy.log
    echo
    echo "=== directories from the common role ==="
    sudo ls -ld /opt/apps /opt/logs
    echo
    echo "=== nginx state after the role's Restart nginx handler (config has no events{} block) ==="
    systemctl is-active nginx
    echo
    echo "=== role order in the log: common runs twice, because monitoring depends on it ==="
    grep -E "^TASK \[" roles_run.txt
    echo
    echo "=== conditional role usage: webserver is skipped on a non-Ubuntu box ==="
    sed -n '/TASK \[Include webserver role\]/,/TASK \[Use role with custom vars\]/p' roles_run.txt \
        | grep -E "^(TASK|skipping|ok|changed|fatal|failed)"
    echo
    echo "=== health check against :8080 while the rendered nginx listens on :80 ==="
    echo "=== the uri task reports ok anyway, because failed_when: false swallows it ==="
    sed -n '/TASK \[Verify deployment\]/,/TASK \[Log deployment\]/p' roles_run.txt \
        | grep -E "^(TASK|ok|changed|skipped|fatal|failed)"
    echo "--- the same request from the shell, so the real reason is visible ---"
    curl -sS -m 5 http://localhost:8080; echo "curl exit code: $?"
    echo
    echo "=== --tags monitoring: only common + monitoring run, webserver is not touched ==="
    grep -E "^TASK \[" roles_tags_monitoring.txt
} > roles_evidence.txt 2>&1

echo "4.1 roles completed. Reports: roles_tree.txt, roles_run.txt, roles_tags_monitoring.txt, roles_evidence.txt"
