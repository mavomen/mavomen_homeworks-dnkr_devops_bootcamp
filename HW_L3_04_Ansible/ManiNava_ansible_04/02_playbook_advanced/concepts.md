# Templates & Handlers - notes for 2.1

## Templates (Jinja2)

A template is a normal text file with Jinja2 in it, and `template:` renders
it on the target. Two files live in `templates/`:

- `nginx.conf.j2` - a full nginx config. `{{ ansible_processor_vcpus }}`
  becomes `worker_processes 8`, `{% if enable_gzip %}` keeps or drops the
  `gzip on;` block, `listen {{ nginx_port }}` / `server_name {{ server_name }}`
  / `root {{ nginx_root }}` come from the play `vars:`.
- `app.conf.j2` - an INI file with a real condition
  (`{% if environment == 'production' %}` picks `db_host`, and the run log
  shows `db_host=localhost` because `environment` is `development`), plus a
  loop (`{% for user in app_users %}`) that writes one `name=role` line per
  entry, so the rendered file has `admin=administrator` and `user1=user`.

Rendering is idempotent by design: if the rendered result is byte-for-byte
the same as what is already on disk, ansible reports `ok`, not `changed`,
and nothing downstream is notified. That is exactly what the second run in
`handlers_templates_rerun.txt` shows.

`backup: yes` on the nginx task keeps a timestamped copy of the old file
next to it, so I can always diff what the template replaced.

## Handlers

A handler is a task that runs **at the end of the play**, and only if some
task asked for it with `notify:`. In this playbook:

    - name: Generate nginx config
      template: ...
      notify: Restart nginx

    - name: Deploy index page
      copy: ...
      notify: Reload nginx

Both tasks are `changed` on the first run, so the log ends with

    RUNNING HANDLER (Restart nginx)
    RUNNING HANDLER (Reload nginx)

If a task does not change anything, the handler is not notified at all.
Two things make that visible in my evidence: the nginx template does not
contain a timestamp, so on the second run it is `ok` and `Restart nginx`
stays silent, while `index.html` embeds `ansible_date_time.iso8601` and is
therefore always `changed`, so `Reload nginx` fires every time. Same
playbook, two handlers, two different trigger behaviours - notify is tied
to *changed*, not to "the task ran".

Handlers also fire once per play no matter how many tasks notify them,
they run in the order they are defined in `handlers:`, and they never run
if the play failed before them unless `force_handlers` is used.

## The error-handling playbook (2.2)

Small playbook, but it shows the four tools you need when something goes
wrong:

- `ignore_errors: yes` - carry on and mark the task failed instead of
  aborting the whole play.
- `failed_when:` - redefine what "failure" means. Here
  `'Error' in result.stdout` fails the task even though the shell command
  itself exited 0.
- `changed_when: false` - run something for its output but never report it
  as a change, so it does not trigger handlers or make the run look dirty.
- `block: / rescue: / always:` - the classic pattern. The `Risky task` runs
  `/bin/false`, so `rescue` fires and prints "Error handled gracefully",
  and `always` runs whether the block succeeded or not.

The `assert` task is the honest example of a *real* failure: this box is
Arch, `ansible_distribution in ["Ubuntu", "Debian"]` is false, so the task
fails with `fail_msg: "Requirements not met"`. It carries
`ignore_errors: yes` so the rest of the playbook still runs, and the log
shows both the message and the `ignoring` line.
