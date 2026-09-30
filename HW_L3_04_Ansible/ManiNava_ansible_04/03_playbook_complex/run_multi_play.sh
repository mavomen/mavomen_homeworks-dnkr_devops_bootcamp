#!/bin/bash
# 3.1 - multi-play orchestration with import_tasks / include_tasks
# The inventory has to be passed with -i here, otherwise plays 2 and 3 find
# no host named "webservers" / "dbservers" and skip everything.
set -u
SCEN_DIR="$(cd "$(dirname "$0")" && pwd)"
SUBMIT="$(dirname "$SCEN_DIR")"
export ANSIBLE_CONFIG="$SUBMIT/ansible.cfg"
cd "$SCEN_DIR"

sudo mkdir -p /var/www/html /opt/apps /opt/logs

echo "--- 3.1a inventory graph ---"
ansible-inventory -i inventory --graph 2>&1 | tee inventory_graph.txt

echo "--- 3.1b flat inventory (who is in which group) ---"
ansible-inventory -i inventory --list 2>&1 | tee inventory_list.txt

echo "--- 3.1c multi-play run ---"
ansible-playbook multi_play.yml -i inventory 2>&1 | tee multi_play_run.txt

{
    echo "=== /opt/apps/host.conf written by the *included* configure.yml ==="
    sudo cat /opt/apps/host.conf
    echo
    echo "=== directories created by the loop in configure.yml ==="
    sudo ls -ld /opt/apps /opt/logs
    echo
    echo "=== web page written by play 2 (hosts: webservers -> web1 only) ==="
    sudo cat /var/www/html/index.html
    echo
    echo "=== db files written by play 3 (hosts: dbservers -> db1 only) ==="
    sudo cat /etc/my.cnf
    sudo ls -ld /var/lib/mydb
    echo
    echo "=== plays recap: one play per group ==="
    grep -n "^PLAY " multi_play_run.txt
    echo
    echo "=== tasks of play 1 only (hosts: all -> web1 + db1) ==="
    awk '/^PLAY .*all servers/,/^PLAY .*web servers/' multi_play_run.txt | grep -E "^TASK " | head -20
} > multi_play_evidence.txt 2>&1

echo "3.1 multi_play completed. Reports: inventory_graph.txt, inventory_list.txt, multi_play_run.txt, multi_play_evidence.txt"
