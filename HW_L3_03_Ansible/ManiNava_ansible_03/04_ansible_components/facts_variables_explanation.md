# Facts & Variables Explanation

## 1. What are Facts?

Facts are **information Ansible collects from the target machines** at the
start of a run (gathering phase). With `gather_facts: yes` (the default in
playbooks; on the CLI they appear through the `setup` module) Ansible
queries every host and loads the answers into `ansible_facts`:

- **System info**: hostname, OS distribution (`ansible_distribution`,
  `ansible_distribution_version`), architecture (`ansible_architecture`),
  kernel (`ansible_kernel`);
- **Network info**: IP addresses (`ansible_default_ipv4`), interfaces
  (`ansible_interfaces`, `ansible_all_ipv4_addresses`);
- **Hardware info**: CPU cores (`ansible_processor_cores`), total memory
  (`ansible_memtotal_mb`), disks (`ansible_devices`).

How to view them:

- `ansible localhost -m setup` - full fact dump for one host;
- `ansible localhost -m setup -a "filter=ansible_distribution*"` - only
  matching facts;
- in playbooks: `{{ ansible_facts['distribution'] }}`.

`ansible_facts` vs `ansible_*`: the modern storage is the dict
`ansible_facts` (namespace `ansible_facts.distribution`); the older,
"magic" top-level variables like `ansible_distribution` are still
available and automatically mirrored from `ansible_facts` in most cases,
but new code should use `ansible_facts['...']`.

## 2. How are Variables defined in Ansible?

Four common places:

- **in a playbook** under `vars:`:

  ```yaml
  hosts: all
  vars:
    http_port: 80
  ```

- **in the inventory** under `[group:vars]` (as in our `inventory` file -
  `http_port`, `db_port`);
- **on the command line** with extra vars: `ansible-playbook -e
  "http_port=8080"` (or `--extra-vars`);
- **in separate files** referenced by `vars_files:` in a playbook;

plus group_vars/host_vars directories and facts themselves.

**Precedence** (low -> high, simplified): role defaults < inventory group
vars < inventory host vars < playbook `vars:` < `vars_files` < extra vars
(`-e`). So `-e` wins over everything - useful for quick overrides and
unwanted for permanent settings.

**Using variables** - reference them with the Jinja2 templating syntax:
`{{ variable_name }}` (e.g. `port={{ http_port }}` in a task argument or
a template file). **Jinja2** is the templating engine of Ansible: besides
plain variables it offers filters (`{{ name | upper }}`), conditionals
(`{% if %}`), and loops (`{% for ... %}`) inside templates and task
arguments.

`facts_demo.txt` and `facts_all.json` show the raw reality: the setup
module returned hundreds of facts for localhost, and the filtered rows
proved `ansible_distribution`, `ansible_default_ipv4` and
`ansible_memtotal_mb` are populated on this Arch box.