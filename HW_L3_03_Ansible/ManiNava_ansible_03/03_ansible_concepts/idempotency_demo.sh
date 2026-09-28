#!/bin/bash
# 3.1 - Idempotency demo: first run creates, later runs are no-ops
cd "$(dirname "$(readlink -f "$0")")"

echo -e "=== First Run should create ===" > idempotency_demo.txt
ansible localhost -m file -a "path=/tmp/ansible_idempotency state=directory" >> idempotency_demo.txt

echo -e "\n=== Second Run should NOT create, changed=false ===" >> idempotency_demo.txt
ansible localhost -m file -a "path=/tmp/ansible_idempotency state=directory" >> idempotency_demo.txt

echo -e "\n=== Third Run should NOT create, changed=false ===" >> idempotency_demo.txt
ansible localhost -m file -a "path=/tmp/ansible_idempotency state=directory" >> idempotency_demo.txt

echo "3.1 idempotency_demo completed. Report: idempotency_demo.txt (expect changed:true only on the first run)"