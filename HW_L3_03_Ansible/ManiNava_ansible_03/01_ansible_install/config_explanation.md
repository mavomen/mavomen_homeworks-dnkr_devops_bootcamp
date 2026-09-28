# Config Explanation - ansible.cfg directives

Below is a line-by-line explanation of every directive present in the
`ansible_config/ansible.cfg` file.

## [defaults]

- `inventory = ./inventory`
  Path to the inventory file (relative to the folder where ansible runs).
  This is the list of managed nodes. Here it points to our local test
  inventory that contains the `[local]` group.
- `host_key_checking = False`
  Disables SSH host-key verification. In production you never want this -
  it would allow man-in-the-middle attacks; it is only handy for throwaway
  lab/VMs where keys change constantly. Production should use real
  fingerprints or `known_hosts`.
- `remote_user = ubuntu`
  The default SSH user ansible connects as. Matches the typical Ubuntu
  cloud/VM default. Overridable per-host with `ansible_user`.
- `private_key_file = ~/.ssh/id_rsa`
  Default private key for SSH authentication. On our test setup it is
  irrelevent (we use `ansible_connection=local`), but kept for the
  ssh-based targets commented in the inventory.
- `retry_files_enabled = False`
  Disables the `.retry` files that ansible used to leave next to a
  playbook after failures. Keeps the workspace clean.
- `stdout_callback = yaml`
  Formats command output as YAML instead of the compact default. Much
  nicer to read the module results (you will see it in every output below).
- `deprecation_warnings = True`
  Shows warnings when a task uses a feature that is going away in a future
  version, so the playbooks stay forward-compatible.

## [privilege_escalation]

- `become = True`
  Default for task escalation - ansible switches to a privileged user
  when a task needs it (equivalent to adding `become: yes` to tasks).
- `become_method = sudo`
  The escalation mechanism is `sudo`.
- `become_user = root`
  Which user the task escalates to (`root`).
- `become_ask_pass = False`
  Do not prompt for a sudo password interactively. Only works with
  passwordless sudo, which is what our lab allows.

## [inventory]

- `enable_plugins = host_list, script, auto, yaml, ini, toml`
  The inventory plugins ansible is allowed to auto-detect when parsing
  inventory sources. `host_list` (comma separated hosts on the CLI),
  `script`, `auto`, `yaml`, `ini` and `toml` cover the common formats so
  a plain INI-file like ours is picked up without extra flags.

Note that with `ansible_connection=local` (see `inventory`), all of these
ssh-related settings are bypassed for the `localhost` host - this machine
is the control node and the managed node at the same time.