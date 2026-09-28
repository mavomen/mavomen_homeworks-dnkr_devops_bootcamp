#!/bin/bash
# 4.1 - Gather facts: full dump, filters, and a saved JSON copy
cd "$(dirname "$(readlink -f "$0")")"

echo "=== All Facts ===" > facts_demo.txt
ansible localhost -m setup >> facts_demo.txt

echo -e "\n=== Distribution Facts ===" >> facts_demo.txt
ansible localhost -m setup -a "filter=ansible_distribution*" >> facts_demo.txt

echo -e "\n=== Network Facts ===" >> facts_demo.txt
ansible localhost -m setup -a "filter=ansible_default_ipv4" >> facts_demo.txt

echo -e "\n=== Memory Facts ===" >> facts_demo.txt
ansible localhost -m setup -a "filter=ansible_memtotal_mb" >> facts_demo.txt

# Save the full fact set as JSON for later reference.
# The default callback decorates the payload with "localhost | SUCCESS => ",
# so we strip that first line's prefix to keep facts_all.json valid JSON.
ansible localhost -m setup 2>/dev/null | sed '1s/^.*=> //' > facts_all.json

echo "4.1 facts_demo completed. Reports: facts_demo.txt, facts_all.json"