#!/bin/bash
# 3.2 - tags
# Five invocations of the same playbook with different tag selections.
#
# Heads up: the "Configure web" task of this demo playbook writes the single
# line "# nginx config" over /etc/nginx/nginx.conf. That is what the task in
# the assignment does, but it leaves an unusable config on the box, so the
# script keeps a copy of the real one before running and puts it back after
# (both copies stay next to the reports as evidence).
set -u
SCEN_DIR="$(cd "$(dirname "$0")" && pwd)"
SUBMIT="$(dirname "$SCEN_DIR")"
export ANSIBLE_CONFIG="$SUBMIT/ansible.cfg"
cd "$SCEN_DIR"

sudo mkdir -p /var/www/html
sudo cp -a /etc/nginx/nginx.conf ./nginx.conf.before_tags

echo "--- 3.2a which tags exist? ---"
ansible-playbook tags_demo.yml --list-tags 2>&1 | tee tags_list.txt

echo "--- 3.2b only the install tasks (+ the always one) ---"
ansible-playbook tags_demo.yml --tags install 2>&1 | tee tags_install.txt

echo "--- 3.2c only the webserver tasks (one install + one configure) ---"
ansible-playbook tags_demo.yml --tags webserver 2>&1 | tee tags_webserver.txt

echo "--- 3.2d everything except the configure tasks ---"
ansible-playbook tags_demo.yml --skip-tags configure 2>&1 | tee tags_skip_configure.txt

echo "--- 3.2e the task that never runs unless you ask for it ---"
ansible-playbook tags_demo.yml --tags never 2>&1 | tee tags_never.txt

# what the tag demo left on disk, before restoring
sudo cp -a /etc/nginx/nginx.conf ./nginx.conf.during_tags
sudo cp -a ./nginx.conf.before_tags /etc/nginx/nginx.conf

{
    echo "=== /etc/nginx/nginx.conf after the tag runs (placeholder written by 'Configure web') ==="
    cat nginx.conf.during_tags
    echo
    echo "=== diff against the real config before the demo ==="
    diff nginx.conf.before_tags nginx.conf.during_tags
    echo
    echo "=== tasks each tag selection actually ran ==="
    for f in tags_install tags_webserver tags_skip_configure tags_never; do
        echo "--- $f ---"
        grep -E "^TASK " "$f.txt"
    done
    echo
    echo "=== real config restored: identical to the pre-demo copy ==="
    diff nginx.conf.before_tags <(sudo cat /etc/nginx/nginx.conf) && echo "restore: identical"
    echo
    echo "=== nginx -t on the restored file still reports the missing events{} block (see README) ==="
    sudo nginx -t 2>&1
} > tags_evidence.txt 2>&1

echo "3.2 tags completed. Reports: tags_list.txt, tags_install.txt, tags_webserver.txt, tags_skip_configure.txt, tags_never.txt, tags_evidence.txt"
