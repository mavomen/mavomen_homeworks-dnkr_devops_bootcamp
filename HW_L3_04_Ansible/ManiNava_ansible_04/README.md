# ManiNava Ansible Playbooks & Roles Homework 04

Ansible homework for the DevOps bootcamp (week 3), the playbooks & roles
part. Every playbook from the assignment is copied as it is and runs on my
own machine: control node and target are both `localhost` with
`connection: local` / `ansible_connection=local`, and `become: yes` is
handled by passwordless sudo.

## 1. Short description

Four sections, seven playbooks, one set of roles:

- `01` **playbook basics** - a first playbook with variables and facts
  (1.1, 5 points), then loops, conditionals and `register` + `when`
  (1.2, 7 points);
- `02` **playbook advanced** - Jinja2 templates and handlers
  (`template`, `notify`, `backup: yes`) (2.1, 8 points), then the error
  handling patterns `ignore_errors`, `failed_when`, `changed_when` and
  `block`/`rescue`/`always` (2.2, 4 points);
- `03` **playbook complex** - one playbook with three plays, an inventory
  with groups, and `import_tasks` vs `include_tasks` (3.1, 8 points), then
  tag selection with `--tags` / `--skip-tags` (3.2, 4 points);
- `04` **roles** - `common`, `webserver` and `monitoring` (including a
  `meta/main.yml` dependency), a `deploy.yml` with pre/post tasks, role
  tags and `include_role` (4.1, 11 points).

## 2. How to run

Each script starts in its own folder, exports `ANSIBLE_CONFIG` to the
shared `ansible.cfg` in the submission root and writes its reports next to
itself:

```bash
cd ManiNava_ansible_04
./01_playbook_basics/run_first_playbook.sh        # 1.1
./01_playbook_basics/run_conditionals_loops.sh    # 1.2
./02_playbook_advanced/run_handlers_templates.sh  # 2.1
./02_playbook_advanced/run_error_handling.sh      # 2.2
./03_playbook_complex/run_multi_play.sh           # 3.1
./03_playbook_complex/run_tags.sh                 # 3.2
./04_ansible_roles/run_roles.sh                   # 4.1
```

The same commands by hand (this is what the scripts run):

```bash
ansible-playbook first_playbook.yml
ansible-playbook first_playbook.yml --syntax-check
ansible-playbook first_playbook.yml -e "app_port=9090 app_version=2.0.0"
ansible-playbook conditionals_loops.yml
ansible-playbook handlers_templates.yml
ansible-playbook error_handling.yml
ansible-inventory -i inventory --graph
ansible-playbook multi_play.yml -i inventory
ansible-playbook tags_demo.yml --list-tags
ansible-playbook tags_demo.yml --tags install
ansible-playbook tags_demo.yml --tags webserver
ansible-playbook tags_demo.yml --skip-tags configure
ansible-playbook tags_demo.yml --tags never
ansible-playbook deploy.yml
ansible-playbook deploy.yml --tags monitoring
```

`ansible.cfg` (submission root) sets `host_key_checking = False`,
`retry_files_enabled = False`, `nocows`, `display_skipped_hosts = True`,
`interpreter_python = auto_silent` and `roles_path = ./roles`. There is no
global `inventory` line on purpose: sections 01, 02 and 04 use the
implicit `localhost`, and only section 03 gets an explicit `-i inventory`,
otherwise the `hosts: webservers` / `hosts: dbservers` plays would find no
host and skip everything.

## 3. File structure

```
ManiNava_ansible_04/
├── ansible.cfg                   # shared config (ANSIBLE_CONFIG)
├── 01_playbook_basics/           # 1.1 + 1.2
│   ├── first_playbook.yml        #   variables, facts, set_fact
│   ├── conditionals_loops.yml    #   loop, when, register
│   ├── concepts.md               #   1.1 notes
│   ├── loops_explanation.md      #   1.2 notes
│   ├── run_first_playbook.sh
│   └── run_conditionals_loops.sh
├── 02_playbook_advanced/         # 2.1 + 2.2
│   ├── handlers_templates.yml    #   template + notify
│   ├── error_handling.yml        #   ignore/failed/changed + block-rescue
│   ├── templates/
│   │   ├── nginx.conf.j2
│   │   └── app.conf.j2
│   ├── concepts.md               #   2.1 + 2.2 notes
│   ├── run_handlers_templates.sh
│   └── run_error_handling.sh
├── 03_playbook_complex/          # 3.1 + 3.2
│   ├── inventory                 #   [webservers] [dbservers] [all:children]
│   ├── multi_play.yml            #   3 plays, one per group
│   ├── tags_demo.yml
│   ├── tasks/
│   │   ├── install.yml           #   imported (static)
│   │   └── configure.yml         #   included (dynamic, gets vars)
│   ├── concepts.md               #   3.1 + 3.2 notes
│   ├── run_multi_play.sh
│   └── run_tags.sh
├── 04_ansible_roles/             # 4.1
│   ├── deploy.yml                #   roles + pre/post tasks + include_role
│   ├── roles_concepts.md         #   role notes
│   ├── roles/
│   │   ├── common/               #   apt guard, /opt/apps, /opt/logs
│   │   ├── webserver/            #   nginx + index.html.j2 + handler
│   │   └── monitoring/           #   depends on common (meta/main.yml)
│   └── run_roles.sh
├── README.md
├── overview_qa.txt               # Q&A recap + every deviation explained
├── playbook_runs.txt             # key commands per scenario
├── commands_history.txt          # same list, repo naming convention
└── final_structure.txt           # find output of this folder
```

Every `*.txt` next to the playbooks is a generated report (run log,
rendered file content, `nginx -t`, inventory graph, and so on); the role
folders are the untouched `ansible-galaxy init` skeleton plus the task
bodies from the assignment.

## 4. Notes on this environment (please read)

The assignment targets Ubuntu 22.04. I ran everything natively on Arch
Linux with `ansible-playbook` 2.21.1 from the distro packages, so the
differences you can see in the logs are expected and every one of them is
listed in `overview_qa.txt`. The short list:

1. **`apt` tasks fail and are ignored.** The playbooks use the `apt`
   module, which does not exist on Arch. Each of those tasks already
   carries `ignore_errors: yes` in the assignment, so the plays continue
   and the logs show the module errors. I did not swap the module, the
   playbooks are copied verbatim.
2. **`nginx.conf.j2` has no `events {}` block**, which nginx requires, so
   `nginx -t` on the rendered file says `no "events" section in
   configuration` and the `Restart nginx` / `Reload nginx` handlers report
   a failure that is then ignored (again by the assignment's own
   `ignore_errors: yes`). This is a defect in the assignment's template and
   it behaves exactly the same way on Ubuntu 22.04 - I verified that adding
   a single `events {}` line makes the very same rendered file pass
   `nginx -t`, so the substitution itself is correct. The template is left
   untouched.
3. **`deploy.yml`: one `---` less.** The assignment shows a second
   `---` before the "Conditional Role Usage" play. A playbook has to be a
   single YAML document, so with that separator ansible refuses to parse
   the file (`Expected a single document in the stream`). I dropped the
   separator and kept both plays in `deploy.yml` as one document, which is
   valid because a playbook is a list of plays.
4. **`tags_demo.yml` overwrites the real nginx config** with the single
   line `# nginx config` (that is what the task in the assignment does).
   `run_tags.sh` saves `/etc/nginx/nginx.conf` before the tag runs, keeps
   the placeholder as evidence and restores the real file afterwards, then
   checks it again with `nginx -t`.
5. **`uri http://localhost:8080`** in `deploy.yml` post_tasks cannot
   succeed, because the nginx config the assignment renders listens on
   port 80. `failed_when: false` is exactly what keeps the play alive, and
   the registered result is in the log.
6. **Host preparation**: `nginx` installed with pacman, the `www-data`
   system user and `/var/www/html` created, because the templates assume
   the Ubuntu layout. The exact commands are in the transcript header of
   `S0.1`.

## 5. After the run (cleanup)

The scripts only create things; nothing is removed while the run goes on,
because the later sections read what the earlier ones wrote. Afterwards
this is what I removed from the machine:

```bash
sudo systemctl stop nginx && sudo systemctl reset-failed nginx
sudo rm -rf /opt/MyApp /opt/myapp /opt/apps /opt/logs /opt/scripts
sudo rm -rf /etc/myapp /var/lib/mydb && sudo rm -f /etc/my.cnf
sudo userdel -r user1 && sudo userdel -r user2
```

Kept on purpose: the `nginx` package, the `www-data` system user,
`/var/www/html` and `/etc/nginx/nginx.conf` with its `backup: yes` copy,
so the rendered configuration can still be inspected after the run.

## 6. Concepts (summary)

- **Playbook structure** - `name`, `hosts`, `become`, `gather_facts`,
  `vars`, `tasks`; each task is one module call.
- **Variable precedence** - `-e` extra vars > `set_fact`/`register` >
  play `vars` > inventory vars > facts. Proven by the `-e` run rewriting
  `/opt/MyApp/config.env` with `APP_PORT=9090`.
- **Facts** - `ansible_hostname`, `ansible_distribution`,
  `ansible_os_family`, `ansible_memtotal_mb`, `ansible_date_time`.
- **Loops & conditionals** - `loop` over lists of strings or dicts,
  `when` with single or multiple conditions (implicit `and`), `register` +
  a condition on the result for check-then-act.
- **Templates** - Jinja2 `{{ }}`, `{% if %}`, `{% for %}`; idempotent
  because an unchanged render is `ok`, not `changed`.
- **Handlers** - `notify:` + `handlers:`; they run once at the end of the
  play and only for tasks that reported `changed`. The nginx template is
  stable between runs, so its handler stays silent, while `index.html`
  carries a timestamp and its handler fires every time.
- **Error handling** - `ignore_errors`, `failed_when`, `changed_when`,
  `assert` with `fail_msg`/`success_msg`, `block`/`rescue`/`always`.
- **Multi-play & inventory** - several plays in one playbook, each against
  its own group; `import_tasks` is static (parse time), `include_tasks` is
  dynamic (execution time) and can take per-include `vars`.
- **Tags** - `--tags`, `--skip-tags`, `--list-tags`; `always` and `never`
  as special tags.
- **Roles** - `tasks/`, `defaults/`, `handlers/`, `templates/`, `meta/`
  (dependencies), `ansible-galaxy init`, role variables overridden from the
  playbook, `include_role` with `when` and `vars`.
- **Idempotency** - the second run of every playbook is mostly `ok` (wich
  is the whole point of running the same playbook twice).
