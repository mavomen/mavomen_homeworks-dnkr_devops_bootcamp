#!/bin/bash
# 1.1 - Install Ansible with pip (--user)
# Note: this machine runs Arch, so the apt lines from the PDF are kept as
# comments; python3/python3-pip/python3-venv are already present here.
set -e
cd "$(dirname "$(readlink -f "$0")")"

# Install Python and pip if not installed (Debian/Ubuntu only)
# sudo apt update
# sudo apt install -y python3 python3-pip python3-venv

# Install Ansible with pip.
# Arch enables PEP 668 (externally-managed), so the plain pip command is
# refused; we then retry with the documented --break-system-packages flag.
if pip3 install --user ansible >/tmp/pip_ansible.log 2>&1; then
    echo "pip3 install --user ansible: OK"
else
    echo "PEP 668 refused the plain command; retrying with the documented override flag"
    pip3 install --user --break-system-packages ansible 2>&1 | tail -n 12
fi

# Add pip bin to PATH
export PATH=$PATH:~/.local/bin

# Check version
ansible --version > ansible_version.txt

# Check installed modules (dump the full list to a temp file first:
# `ansible-doc -l | head` crashes with a broken-pipe traceback on newer
# ansible, so we truncate after writing the list)
ansible-doc -l > /tmp/ansible_doc_list.txt 2>/dev/null || true
head -30 /tmp/ansible_doc_list.txt >> ansible_version.txt

# Check total number of modules
echo "Total modules: $(wc -l < /tmp/ansible_doc_list.txt)" >> ansible_version.txt
rm -f /tmp/ansible_doc_list.txt /tmp/pip_ansible.log

{
    echo "=== which ansible ==="
    which ansible
    echo
    echo "=== ansible --version ==="
    ansible --version
    echo
    echo "=== ansible-config dump | head -30 ==="
    ansible-config dump | head -30
    echo
    echo "=== python3 --version ==="
    python3 --version
    echo
    echo "=== pip3 show ansible ==="
    pip3 show ansible
} > ansible_status.txt

echo "1.1 install_ansible completed. Reports: ansible_version.txt, ansible_status.txt"