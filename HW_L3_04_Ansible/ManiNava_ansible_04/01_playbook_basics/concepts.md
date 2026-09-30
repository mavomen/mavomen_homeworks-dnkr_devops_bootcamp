# Playbook & Variables - notes for 1.1

`first_playbook.yml` is the smallest playbook that still shows the whole
idea: describe the desired state once, then run it as many times as you want.

## The skeleton

- `name:` - what this play is doing, it shows up at the top of every run.
- `hosts:` - the target group from the inventory. Here it is `localhost`
  with `connection: local`, so the "remote" machine is my own box.
- `gather_facts: yes` - collect the system facts before the first task
  (`ansible_hostname`, `ansible_distribution`, `ansible_memtotal_mb`,
  `ansible_date_time` all come from there).
- `vars:` - play level variables.
- `tasks:` - the actual work, each task is one module call.

## Where variables come from (precedence, highest first)

1. `-e "app_port=9090"` on the command line - extra vars beat everything.
2. `set_fact:` and anything stored with `register:` - they live until the
   end of the play and win over `vars:`.
3. Play `vars:` - what I use in this playbook (`app_name`, `app_version`,
   `app_port`, `app_home`).
4. Inventory `host_vars` / `group_vars`, then inventory inline vars.
5. Facts collected by `gather_facts`.

I proved 1 vs 3 by running the same playbook twice: the plain run wrote
`APP_PORT=8080` into `/opt/MyApp/config.env`, and the run with
`-e "app_port=9090 app_version=2.0.0"` rewrote the same file with
`APP_PORT=9090` / `APP_VERSION=2.0.0`. Both logs are in this folder
(`first_playbook_run.txt` and `first_playbook_extra_vars.txt`, the file
content itself in `config_env.txt`).

`app_home: "/opt/{{ app_name }}"` shows Jinja2 inside a variable - the
value is not fixed text, it is built from another variable, so the
directory is `/opt/MyApp` without me hardcoding it.

`set_fact` is the interesting one: `deployment_time` and
`deployment_user` do not exist anywhere in the inventory, I create them
mid-play and the next task prints them. That is how you pass data between
tasks without files.

`ignore_errors: yes` on the two writing tasks is not hiding anything: the
directory and the config file really are created (root-owned, the run
log shows `changed: true`), it only means a failure there would not stop
the play.