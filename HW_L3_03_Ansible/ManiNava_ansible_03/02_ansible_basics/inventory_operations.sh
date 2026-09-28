#!/bin/bash
# 2.2 - Working with the inventory: JSON/YAML views, groups, variables, ping
cd "$(dirname "$(readlink -f "$0")")"

# View inventory as JSON
echo "=== Inventory as JSON ===" > inventory_operations.txt
ansible-inventory -i inventory --list >> inventory_operations.txt

# View inventory as YAML
echo -e "\n=== Inventory as YAML ===" >> inventory_operations.txt
ansible-inventory -i inventory --list --yaml >> inventory_operations.txt

# Show hosts/variables in the webservers group
echo -e "\n=== Webservers Group ===" >> inventory_operations.txt
ansible-inventory -i inventory --host web1 >> inventory_operations.txt

# Show all hosts
echo -e "\n=== All Hosts ===" >> inventory_operations.txt
ansible all -i inventory --list-hosts >> inventory_operations.txt

# Show hosts in the production parent group
echo -e "\n=== Production Group Children ===" >> inventory_operations.txt
ansible production -i inventory --list-hosts >> inventory_operations.txt

# Show variables for a single host
echo -e "\n=== Variables for web1 ===" >> inventory_operations.txt
ansible-inventory -i inventory --host web1 >> inventory_operations.txt

# Ping all hosts
echo -e "\n=== Ping All Hosts ===" >> inventory_operations.txt
ansible all -i inventory -m ping >> inventory_operations.txt

echo "2.2 inventory_operations completed. Report: inventory_operations.txt"