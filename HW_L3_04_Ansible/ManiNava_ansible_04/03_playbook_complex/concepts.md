# Multi-play, import & include - notes for 3.1

## Inventory groups

`inventory` describes the machines, in three blocks:

    [webservers]
    web1 ansible_host=localhost ansible_connection=local

    [dbservers]
    db1 ansible_host=localhost ansible_connection=local

    [all:children]
    webservers
    dbservers

Inline vars (`ansible_host`, `ansible_connection`) replace the host's
`ssh` defaults, so both "servers" are really my own machine with a local
connection - the point of this exercise is the *grouping*, not multiple
hardware. `ansible-inventory --graph` (saved as `inventory_graph.txt`)
shows the tree: `all` with its two children, `web1` under `webservers`
and `db1` under `dbservers`.

## Three plays, one file

`multi_play.yml` is not three playbooks, it is one playbook with three
plays, and they run in order, each one against its own group:

1. `hosts: all` - common setup for everything (`gather_facts: yes`,
   `become: yes`), the shared `packages` / `directories` vars.
2. `hosts: webservers` - installs nginx and writes the web page, so only
   `web1` runs it.
3. `hosts: dbservers` - creates `/var/lib/mydb` and `/etc/my.cnf`, so only
   `db1` runs it.

Play 1's `apt` task is guarded by `when: ansible_os_family == "Debian"`,
so on my Arch box it is skipped while the directory loops still run.

## import_tasks vs include_tasks

Both pull another YAML file in, the difference is *when*:

- `import_tasks: tasks/install.yml` - static. The file is read and
  inlined while the playbook is parsed, before anything runs. Its tasks
  become real tasks of the play, they inherit the play's keywords
  (`become`, `gather_facts`, `vars`) and they cannot be wrapped in a
  `when` or a `loop` by the caller.
- `include_tasks: tasks/configure.yml` - dynamic. The file is read at
  execution time, when the task is reached. That is why I can pass
  per-include variables to it:

        - name: Include configuration
          include_tasks: tasks/configure.yml
          vars:
            config_content: "HOSTNAME={{ ansible_hostname }}\n"
            config_path: "/opt/apps/host.conf"

  and that is why an included file can be skipped or looped over.

Practical rule of thumb: use `import_*` for "these tasks are part of this
play", and `include_*` when the variables or the condition depend on
something you only know while the play is running.

## tags_demo.yml (3.2)

Same playbook, different subsets, selected with `--tags` / `--skip-tags`:

- `--tags install` runs only the two `install` tasks (nginx, mysql) and the
  `always` one, because `always` is a special tag ansible adds to every
  task.
- `--tags webserver` picks the tasks tagged `webserver`, which is one
  install task *and* one configure task, because both carry that tag.
- `--skip-tags configure` runs everything except the tasks tagged
  `configure` - the opposite switch, same idea.
- `--tags never` finally reaches the task nobody runs by default.
- `--list-tags` just prints the tag list without touching the machine.

One warning about this playbook: the two `Configure` tasks write their
comment lines straight over `/etc/nginx/nginx.conf` and
`/etc/mysql/my.cnf`. It is a tag demo, not a real config, so
`run_tags.sh` saves the real nginx config before running and puts it back
afterwards (both copies are kept next to the reports).
