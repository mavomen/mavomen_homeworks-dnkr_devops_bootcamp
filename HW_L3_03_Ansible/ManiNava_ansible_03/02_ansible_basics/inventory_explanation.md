# Inventory Explanation

## 1. What is the Inventory and what is its role?

The inventory is the **list of managed nodes** that Ansible works with,
plus all the data needed to reach them. It defines:

- hosts (with `ansible_host`, `ansible_user`, `ansible_connection`...);
- groups of hosts (`[webservers]`, `[dbservers]`, ...);
- group and host variables (`http_port=80`, `ansible_user=ubuntu`...);
- parent/child relations between groups.

Its role: Ansible's first step on every run is reading the inventory - it
decides *which* machines a pattern (`all`, `production`, `web1`) matches
and *how* to reach them.

## 2. What is the difference between the INI and YAML formats?

The INI format (used in our file) is compact:

```
[webservers]
web1 ansible_host=localhost ansible_connection=local
```

The YAML format is the same data but structured:

```yaml
all:
  children:
    webservers:
      hosts:
        web1:
          ansible_host: localhost
          ansible_connection: local
```

INI is shorter and easier to type for small inventories; YAML supports the
same features and is preferred when a playbook-style structure or complex
host_vars/group_vars nesting is needed. Both are converted to the same
internal structure - `ansible-inventory` showed us both views of the *same*
inventory.

## 3. What are Groups and Parent Groups?

A **group** is just a collection of hosts with a name - `[webservers]`
groups the web machines so you can target them all with one pattern
(`ansible webservers -m ping`). Hosts can belong to several groups.

A **parent group** (or group-of-groups) is defined with `:children` and
pulls whole *groups* under one name:

```
[production:children]
webservers
dbservers
```

Now `production` matches every host inside `webservers` and `dbservers`
(web1, web2, db1) - handy for grouping an environment (prod/staging) on
top of role groups (web/db/app).

## 4. How are Variables defined in the inventory?

Variables live at three levels:

- **host variables** - inline: `web1 ansible_host=localhost
  ansible_connection=local`;
- **group variables** - via `[group:vars]`:

  ```
  [webservers:vars]
  http_port=80
  max_clients=200
  ```

- **all variables** - via `[all:vars]`, applying to every host.

The `:vars` blocks attach variables to every member of that group, e.g.
every webserver gets `http_port=80`, every dbserver gets `db_port=3306`.

## 5. What does `ansible_connection=local` do?

It tells Ansible: "this host is the control node itself - do not use SSH,
run the modules directly on this machine." The module still executes (in a
Python process) but no network connection is opened. That is exactly how
this whole homework runs - all our targets are localhost, so we skip SSH
keys, usernames and ports entirely and still exercise the full Ansible
flow (inventory, modules, facts, variables).