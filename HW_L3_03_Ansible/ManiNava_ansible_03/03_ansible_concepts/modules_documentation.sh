#!/bin/bash
# 3.2 - Module documentation: list, per-module docs and ping examples
# Note: `ansible-doc ... | head` triggers a BrokenPipe traceback on newer
# ansible/python, so the full output is written to a temp file first and
# then truncated with head/more.
cd "$(dirname "$(readlink -f "$0")")"

echo "=== All Modules ===" > modules_doc.txt
ansible-doc -l > /tmp/ansible_doc_list.txt 2>/dev/null
head -50 /tmp/ansible_doc_list.txt >> modules_doc.txt

# Documentation for apt module
echo -e "\n=== apt Module Documentation ===" >> modules_doc.txt
ansible-doc apt > /tmp/ansible_doc_apt.txt 2>/dev/null
head -100 /tmp/ansible_doc_apt.txt >> modules_doc.txt

# Documentation for file module
echo -e "\n=== file Module Documentation ===" >> modules_doc.txt
ansible-doc file > /tmp/ansible_doc_file.txt 2>/dev/null
head -100 /tmp/ansible_doc_file.txt >> modules_doc.txt

# Documentation for copy module
echo -e "\n=== copy Module Documentation ===" >> modules_doc.txt
ansible-doc copy > /tmp/ansible_doc_copy.txt 2>/dev/null
head -100 /tmp/ansible_doc_copy.txt >> modules_doc.txt

# Examples for ping module
echo -e "\n=== ping Module Examples ===" >> modules_doc.txt
ansible-doc -t module ping > /tmp/ansible_doc_ping.txt 2>/dev/null
grep -A 20 "EXAMPLES" /tmp/ansible_doc_ping.txt >> modules_doc.txt

rm -f /tmp/ansible_doc_list.txt /tmp/ansible_doc_apt.txt /tmp/ansible_doc_file.txt \
      /tmp/ansible_doc_copy.txt /tmp/ansible_doc_ping.txt

echo "3.2 modules_documentation completed. Report: modules_doc.txt"