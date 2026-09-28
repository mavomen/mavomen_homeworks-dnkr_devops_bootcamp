#!/bin/bash
# 1.2 - Test the ansible_config setup (connection + inventory view)
cd "$(dirname "$(readlink -f "$0")")/ansible_config"

# Test connection to localhost
echo "=== Connection Test ===" > connection_test.txt
ansible localhost -m ping >> connection_test.txt

# View inventory as JSON
echo -e "\n=== Inventory List ===" >> connection_test.txt
ansible-inventory --list >> connection_test.txt

# Show hosts
echo -e "\n=== All Hosts ===" >> connection_test.txt
ansible all --list-hosts >> connection_test.txt

# Show variables for localhost
echo -e "\n=== Host Variables ===" >> connection_test.txt
ansible-inventory --host localhost >> connection_test.txt

echo "1.2 test_connection completed. Report: ansible_config/connection_test.txt"