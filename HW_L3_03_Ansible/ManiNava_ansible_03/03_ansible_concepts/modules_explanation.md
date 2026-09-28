# Modules Explanation

## 1. What is a Module?

A module is a **unit of code that performs a specific task** - the actual
"worker" of Ansible. Examples: `ping` checks reachability, `file` manages
paths, `apt` installs/removes packages, `copy` moves files, `service`
controls daemons.

- **Where do modules run?** On the **target machines** (managed nodes) -
  not on the control node. Ansible copies the module code over (SSH /
  connection plugin), runs it, reads its JSON result (`ok/changed/failed`
  + data), then removes the payload.
- **How are they transferred?** Over the same connection Ansible uses for
  that host - SSH on Linux. The module arrives as a small Python script
  (or PowerShell on Windows), is interpreted on the target, and the result
  travels back. Optionally, modules can be transported like other files
  using the `ansible.legacy` transfer mechanism the same way.
- **Built-in vs Custom modules:** built-in ones ship with ansible-core /
  collections (hundreds of them). Custom modules are your own Python (or
  any executable) added under `library/` or a collection - they behave
  exactly like built-ins and take the same `-a` arguments.

## 2. Module types

- **System Modules** - OS-level management: `apt` (Debian packages),
  `yum` (RHEL packages), `service` & `systemd` (services), `user` (accounts),
  `group` (groups). Example uses: `apt: name=nginx state=present`;
  `user: name=deploy state=present`.
- **File Modules** - everything about files: `copy` (copy a file),
  `template` (render Jinja2 to a file), `file` (attributes/paths),
  `lineinfile` / `blockinfile` (edit lines/blocks). Example uses:
  `copy: src=x.conf dest=/etc/x.conf`; `template: src=app.conf.j2 dest=/etc/app.conf`.
- **Command Modules** - run commands: `command` (no shell interpretation),
  `shell` (full shell with pipes/redirects), `script` (run a local script
  on the target), `raw` (low-level, no Python needed). Example uses:
  `command: uptime`; `shell: echo $HOME && whoami`.
- **Cloud Modules** - manage cloud resources: `ec2` (AWS EC2 instances),
  `gce` (Google Compute Engine), `azure_rm` (Azure VMs). Example uses:
  `ec2: instance_type=t2.micro image=ami-... state=running`.
- **Network Modules** - network devices and HTTP: `uri` (HTTP requests),
  `get_url` (download files), `slurp` (read file contents). Example uses:
  `get_url: url=https://... dest=/tmp/x`; `uri: url=http://svc/health status_code=200`.
- **Database Modules** - `mysql_db` (create/drop MySQL databases),
  `postgresql_db` (PostgreSQL databases). Example uses:
  `mysql_db: name=appdb state=present`; `postgresql_db: name=appdb state=present`.

## 3. command vs shell vs raw

| module   | shell features         | Python on target | safety                     |
|----------|------------------------|------------------|----------------------------|
| `command`| none (executes binary directly) | no need (but used only after bootstrap check) | safest, no shell quoting issues |
| `shell`  | pipes, redirects, env vars | yes            | dangerous if you quote wrong |
| `raw`    | everything via shell   | **not required** | lowest level, no modules   |

- `command` executes a command **without** a shell - safer, but you cannot
  use `|`, `>`, `&&` etc. It is also **not idempotent** (runs every time).
- `shell` executes through the shell, so you **can use pipes and
  redirects** (`echo $HOME && whoami` - used in section 05). Configure it
  carefully; prefer `command` whenever pipes are not needed.
- `raw` executes without assuming Python on the target - used to **bootstrap
  machines** that have no Python/PowerShell yet (then install Python and
  switch to real modules).

When to use each: default to `command`; use `shell` only when you really
need shell syntax; use `raw` only in emergency/bootstrap scenarios.