#!/bin/bash
# 4.2 - Configuration dump: full, then grep inventory / ssh / become
cd "$(dirname "$(readlink -f "$0")")"

echo "=== Current Configuration ===" > config_demo.txt
ansible-config dump >> config_demo.txt

echo -e "\n=== Inventory Setting ===" >> config_demo.txt
ansible-config dump | grep inventory >> config_demo.txt

echo -e "\n=== SSH Settings ===" >> config_demo.txt
ansible-config dump | grep -i ssh >> config_demo.txt

echo -e "\n=== Privilege Escalation ===" >> config_demo.txt
ansible-config dump | grep become >> config_demo.txt

echo "4.2 config_demo completed. Report: config_demo.txt"