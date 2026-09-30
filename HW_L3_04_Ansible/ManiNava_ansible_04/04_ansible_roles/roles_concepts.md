# Ansible Roles - notes for 4.1

## What a role is for

A role is a reusable bundle: tasks, defaults, handlers, templates, meta -
all under one directory that you can drop into `roles/` and call by name.
`ansible-galaxy init roles/<name>` creates the skeleton:

    roles/webserver/
    ├── defaults/main.yml     # lowest priority variables
    ├── files/
    ├── handlers/main.yml
    ├── meta/main.yml
    ├── tasks/main.yml        # the actual work
    ├── templates/
    ├── tests/
    └── vars/main.yml         # higher priority than defaults

I created the three roles this way first (`roles_tree.txt` keeps the
list), then filled in the task bodies.

## Variable precedence inside a role

`defaults/main.yml` holds the values that make the role usable without any
configuration:

    webserver_port: 80
    webserver_root: /var/www/html

`deploy.yml` overrides one of them for its own play:

    - role: webserver
      vars:
        webserver_port: 8080

and the rendered `index.html` in `roles_evidence.txt` shows
`<p>Port: 8080</p>` - the play's value won. Anything passed to the role
beats `defaults/`, and `defaults/` beats `vars/`, which is the reason
defaults and not vars should hold role configuration.

## meta/main.yml and dependencies

`roles/monitoring/meta/main.yml` is three lines:

    ---
    dependencies:
      - role: common

So asking for `monitoring` pulls in `common` first, automatically. The
run log proves the order: "Install base packages" and "Create directories"
from `common` appear before "Install monitoring tools", and `deploy.yml`
never mentions `common` in its `roles:` list at all. Dependencies are
resolved depth-first and are not listed twice.

## Two ways to call a role

- `roles:` in the play - static, the role always runs for that play (my
  `common`, `webserver`, `monitoring`, each with `tags:`).
- `tasks:` + `include_role:` - dynamic, so the role can sit inside a
  condition or a loop and get its own variables:

        - name: Include webserver role
          include_role:
            name: webserver
          when: ansible_distribution == "Ubuntu"

        - name: Use role with custom vars
          include_role:
            name: monitoring
          vars:
            monitoring_interval: 60

The first one is skipped on my box (Arch, not Ubuntu) and the log says so
with `skipping` - that is the conditional role usage the assignment asks
for. The second one re-runs `monitoring`, which also re-runs its
`common` dependency, and `monitoring_interval` is available to the role's
tasks even though no `defaults/main.yml` in the role mentions it.

## Handlers inside a role

`roles/webserver/tasks/main.yml` notifies `Restart nginx`, and the handler
lives in the same role (`handlers/main.yml`). Roles bring their own
handlers, you do not have to copy them into the playbook - that is the
main reason the handler follows the task that needs it.
