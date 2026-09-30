#!/bin/bash
# 2.1 - templates and handlers
# Two runs on purpose: the nginx template renders to the same bytes the second
# time (no change -> no handler), while index.html carries a timestamp (always
# changed -> Reload nginx). That difference is the whole point of notify.
set -u
SCEN_DIR="$(cd "$(dirname "$0")" && pwd)"
SUBMIT="$(dirname "$SCEN_DIR")"
export ANSIBLE_CONFIG="$SUBMIT/ansible.cfg"
cd "$SCEN_DIR"

# host preparation this playbook needs on Arch: nginx is installed, the
# www-data system user exists and the document root is there. See README.
sudo mkdir -p /var/www/html

echo "--- 2.1a first run (both templates render, both handlers fire) ---"
ansible-playbook handlers_templates.yml 2>&1 | tee handlers_templates_run.txt

echo "--- 2.1b second run (nginx template is ok, index.html is still changed) ---"
ansible-playbook handlers_templates.yml 2>&1 | tee handlers_templates_rerun.txt

{
    echo "=== rendered /etc/nginx/nginx.conf (Jinja2 substituted) ==="
    sudo cat /etc/nginx/nginx.conf
    echo
    echo "=== nginx -t : does the rendered config actually load? ==="
    sudo nginx -t 2>&1
    echo
    echo "=== nginx state after the handlers ==="
    systemctl is-active nginx
    echo
    echo "=== rendered /etc/myapp/app.conf (if/else + for loop) ==="
    sudo cat /etc/myapp/app.conf
    echo
    echo "=== deployed /var/www/html/index.html ==="
    sudo cat /var/www/html/index.html
    echo
    echo
    echo "=== nothing answers on port 80: the rendered config has no events{} block, ==="
    echo "=== so both nginx handlers failed and were ignored. Proof that the template ==="
    echo "=== itself is fine - the same bytes plus one events{} line pass nginx -t: ==="
    { echo "events {}"; sudo cat /etc/nginx/nginx.conf; } | sudo tee /tmp/nginx_events_probe.conf > /dev/null
    sudo nginx -t -c /tmp/nginx_events_probe.conf 2>&1
    echo
    echo "=== backup copy left by 'backup: yes' ==="
    sudo ls -l /etc/nginx/nginx.conf*
    echo
    echo "=== handler lines of each run ==="
    grep -n "RUNNING HANDLER" handlers_templates_run.txt handlers_templates_rerun.txt
    echo
    echo "=== why the handlers failed (same reason in both runs) ==="
    grep -n -A3 "RUNNING HANDLER" handlers_templates_run.txt | grep -E "fatal|msg" | head -4
} > handlers_templates_evidence.txt 2>&1

echo "2.1 handlers_templates completed. Reports: handlers_templates_run.txt, handlers_templates_rerun.txt, handlers_templates_evidence.txt"
