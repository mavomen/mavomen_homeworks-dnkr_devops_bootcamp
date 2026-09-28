# Ansible - Complete Explanation

## 1. What is Ansible and why is it used?

Ansible is an **automation platform** (provisioning + configuration
management + app deployment + orchestration) owned by Red Hat. With it you
describe the target state of machines in YAML and let Ansible bring them
to that state.

History: created by **Michael DeHaan in 2012** (also the author of Cobbler
and func). He wanted a tool that avoids the complexity of the existing
config-management tools (agent installs, DSL languages, master
infrastructure). In 2015 Red Hat acquired Ansible Inc., and the project
stayed one of the most popular CM tools because of its low learning curve.

Main advantages:

- **Idempotency** - running the same task many times gives the same
  result; nothing is changed twice;
- **Agentless** - no daemon/agent needed on target machines, only SSH and
  Python;
- **Simplicity** - configuration is YAML + a handful of modules, no
  separate programming language to learn;
- **Powerful** - thousands of built-in modules cover system, file,
  network, cloud and database operations.

Difference vs other tools:

- **vs Puppet**: Puppet uses a **pull model** (nodes fetch config from a
  master), Ansible uses **push** (control node pushes commands out);
- **vs Chef**: Chef is more complex (Ruby DSL, chef-server, knives...),
  Ansible is simpler to pick up and debug;
- **vs SaltStack**: SaltStack is faster at massive scale (its minion
  model) but more complex to operate; Ansible trades some raw speed for
  simplicity and zero-agent setup.

## 2. Ansible architecture

```
                 +-------------------------------------------+
                 |              CONTROL NODE                  |
                 |  (where ansible is installed)              |
                 |  - ansible, ansible-playbook, ansible-doc  |
                 |  - inventory files                         |
                 |  - playbooks / ad-hoc commands             |
                 +--------------------+----------------------+
                                      |  SSH (port 22) - for Linux
                                      |  WinRM - for Windows
                                      |  (module payloads pushed over
                                      |   the same connection)
        +-----------------------------+----------------------------------+
        v             v               v                 v                v
 +-------------+ +-------------+ +-------------+  +---------------+  +-----...
 | MANAGED NODE| | MANAGED NODE| | MANAGED NODE|  | MANAGED NODE  |  | ...
 | (web1)      | | (web2)      | | (db1)       |  | (app1)        |  |
 +-------------+ +-------------+ +-------------+  +---------------+  +-----...
   ^                 ^                ^                  ^
   |                 |                |                  |
   +-----------------+----------------+------------------+
                 INVENTORY = list of managed nodes
                 (groups, host variables, connection data)

MODULES: code units (copies of ping, file, apt...) that run on the
         managed node and report back ok/changed/failed.
PLUGINS: extensions (filters, callbacks, connection, inventory, lookup
         plugins) that extend Ansible behaviour without new modules.
```

Key components:

- **Control Node** - the machine where Ansible is installed and where all
  commands/playbooks are launched from (here: our localhost/Arch box);
- **Managed Nodes** - the target systems that Ansible manages (in this
  homework they are localhost itself via `ansible_connection=local`);
- **Inventory** - the list/groups of managed nodes plus their variables;
- **Modules** - small units of code that perform the actual tasks on the
  target machines;
- **Plugins** - add-ons that extend the core (filters, callbacks,
  connections, modules' documentation, etc.).

## 3. Agentless architecture

Ansible **does not need any agent** installed on the managed nodes:

- On **Linux/Unix** it connects over **SSH**. Each run, Ansible copies a
  small Python payload (the module code) to the target, executes it, waits
  for the JSON result, and removes the payload;
- On **Windows** it uses **WinRM** (PowerShell remoting) in the same
  request/response style.

Advantages of agentless:

- simpler install & maintenance - nothing to deploy on the nodes;
- better security - no permanently open agent port (only the standard
  SSH/WinRM port);
- faster start - you can manage a new box just by adding it to the
  inventory.

Disadvantages:

- still needs SSH/WinRM reachable on every target;
- for most modules it needs **Python on the target** (the exception is
  `raw`, which can bootstrap machines without Python).

## 4. Push vs Pull model

- **Push (Ansible)**: the control node pushes the desired state out to
  the managed nodes over SSH, on demand (ad-hoc or playbook run);
- **Pull (Puppet)**: managed nodes run an agent that periodically pulls
  catalogs from the Puppet master.

|                | Push (Ansible)               | Pull (Puppet)                 |
|----------------|------------------------------|-------------------------------|
| direction      | control node -> nodes        | nodes -> server               |
| agent on nodes | no                           | yes                           |
| latency        | immediate (on demand)        | depends on agent interval     |
| scaling        | fine up to thousands of nodes| better at massive fleets      |
| simplicity     | simpler to run & debug       | more moving parts             |

Answer to "why Ansible uses push": push keeps everything agentless and
immediate - you see the result right after the command returns (great for
adhoc ops and CI/CD), there is no agent to install, rotate or keep
compatible, and there is no master-of-masters to babysit. For most teams
that simplicity outweighs the pull model's advantages at truly huge
scales.