# ManiNava Ansible Homework 03

Ansible homework for the DevOps bootcamp (week 3). All scenarios run on
my Arch machine (Ansible installed with `pip3 install --user`, control and
managed node are both `localhost` with `ansible_connection=local`).

## 1. Short description

The homework follows the classic Ansible learning path:

- `01` install Ansible (pip --user), verify version/modules, build
  `ansible.cfg` + `inventory`, test the connection;
- `02` explain what Ansible is and its architecture, and work with
  inventory (groups, parent groups, variables, `ansible-inventory`);
- `03` concepts: idempotency (state management) and modules
  (`ansible-doc`, module types, command vs shell vs raw);
- `04` components: facts & variables (`setup` module) and configuration
  (`ansible-config`);
- `05` ad-hoc commands - ping, setup, file/stat, command/shell, copy,
  get_url and package management.

## 2. Install & configuration

```bash
cd ManiNava_ansible_03
./01_ansible_install/install_ansible.sh      # pip3 install --user ansible
./01_ansible_install/test_connection.sh       # uses ansible_config/ansible.cfg
```

The config lives in `01_ansible_install/ansible_config/`:

- `ansible.cfg` - `inventory = ./inventory`, `stdout_callback = yaml`,
  `host_key_checking = False`, `become` via sudo;
- `inventory` - the `[local]` group (localhost, local connection),
  commented-out ssh targets for `webservers`/`dbservers`, `[all:vars]`
  interpreter setting.

All later sections run the same way (each script starts from its own
folder, fills its own output files and cleans up nothing - they only read).

## 3. File structure & role of each section

```
ManiNava_ansible_03/
├── 01_ansible_install/     # install + config + connection test + notes
│   └── ansible_config/     # ansible.cfg, inventory, connection_test.txt
├── 02_ansible_basics/      # architecture explanation + inventory operations
├── 03_ansible_concepts/    # idempotency demo + modules documentation
├── 04_ansible_components/  # facts/variables demo + configuration dump
├── 05_ansible_adhoc/       # ad-hoc command examples
├── README.md
├── overview_qa.txt        # whole-homework Q&A recap
├── final_structure.txt
└── commands_history.txt   # every ansible command I ran
```

## 4. How to run ad-hoc commands

Structure: `ansible <hosts> -m <module> -a "<arguments>" [options]`

```bash
ansible localhost -m ping                                    # connectivity
ansible all -i 01_ansible_install/ansible_config/inventory -m ping
ansible localhost -m setup -a "filter=ansible_distribution*" # facts
ansible localhost -m file -a "path=/tmp/x state=directory mode=0755"
ansible localhost -m command -a "uptime"
ansible localhost -m shell -a "echo $HOME && whoami"
ansible localhost -m copy -a "src=/tmp/a dest=/tmp/b"
ansible localhost -m get_url -a "url=https://www.google.com dest=/tmp/g.html"
# use --become (sudo) when the module needs root
```

See `05_ansible_adhoc/adhoc_output.txt` for the full results.

## 5. Concepts learned (summary)

- **Agentless & push model** - Ansible needs no agent on targets, it just
  pushes module payloads over SSH (or runs locally).
- **Idempotency** - modules check the current state and change only what
  differs (`changed: true/false` in `idempotency_demo.txt`).
- **State management** - declare the desired state (`state=directory`,
  `state=present`) instead of the actions.
- **Inventory** - groups, parent groups (`:children`), host/group
  variables; `ansible_connection=local` for the local host.
- **Modules** - units of code that run on the targets; `ansible-doc` is
  the offline documentation (list, examples, parameters).
- **Facts & variables** - `ansible_facts` from the `setup` module, var
  precedence and Jinja2 templating.
- **Configuration** - `ansible.cfg` lookup order and the key options
  (`inventory`, `host_key_checking`, `remote_user`, `become`, `gathering`).
- **Ad-hoc vs playbook** - quick one-liners for testing/troubleshooting,
  playbooks for complex reusable tasks.