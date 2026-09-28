# Configuration Management Explanation

## 1. What is `ansible.cfg`?

`ansible.cfg` is the **main configuration file of Ansible** - it replaces
command-line defaults (inventory path, SSH settings, callbacks, escalation
policy, plugins...) and is read on every run.

Priority of config files (first one found wins):

1. `ANSIBLE_CONFIG` environment variable - explicit override;
2. `ansible.cfg` in the **current directory** (what the homework uses in
   `01_ansible_install/ansible_config/`);
3. `~/.ansible.cfg` in the user home;
4. `/etc/ansible/ansible.cfg` - system-wide default.

The most important sections:

- `[defaults]` - general settings (inventory, host_key_checking,
  remote_user, stdout_callback...);
- `[privilege_escalation]` - sudo/su behaviour (become, become_method,
  become_user, become_ask_pass);
- `[inventory]` - inventory plugin discovery
  (`enable_plugins = host_list, script, auto, yaml, ini, toml`).

## 2. Most important configuration options

| option                | meaning                                             |
|-----------------------|-----------------------------------------------------|
| `inventory`           | path to the inventory file(s) used by default       |
| `host_key_checking`   | verify SSH host keys or not (False only for lab!)   |
| `remote_user`         | default user for the SSH connection                 |
| `become` / `become_method` / `become_user` | privilege-escalation defaults (sudo, root) |
| `gathering`           | fact collection policy (`smart`, `implicit`, `explicit`) |

Example from our file:

```
[defaults]
inventory = ./inventory
host_key_checking = False
remote_user = ubuntu
stdout_callback = yaml

[privilege_escalation]
become = True
become_method = sudo
become_user = root
```

`config_demo.txt` shows the live values: `ansible-config dump` prints the
whole effective configuration (with comments), and the greps select the
inventory, SSH and become groups so the important settings are easy to
spot.