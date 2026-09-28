# Ad-Hoc Commands Explanation

## 1. What is an Ad-Hoc Command?

An ad-hoc command is a **fast, one-liner ansible command without a
playbook** - you call one module against a host pattern directly from the
terminal:

```
ansible <hosts> -m <module> -a "<arguments>" [options]
```

When to use ad-hoc:

- **quick, one-time tasks** ("create this dir on 30 servers now");
- **testing & troubleshooting** ("can I reach all hosts? ping");
- **quick changes** ("restart that service", "reboot that host").

Difference vs a playbook:

- **Ad-hoc**: quick, simple, one task at a time, not saved anywhere;
- **Playbook**: complex, reusable, multiple tasks with order/handlers/
  variables - the "real" Ansible workflow.

## 2. Structure of an Ad-Hoc Command

`ansible <hosts> -m <module> -a "<arguments>" [options]`

- `<hosts>` - the target pattern: `all`, a group (`webservers`,
  `production`) or a specific host (`web1`);
- `-m <module>` - which module to run (`ping`, `setup`, `file`,
  `command`, `apt`...);
- `-a "<arguments>"` - module arguments in `key=value` form ("path=/tmp/x
  state=directory");
- `[options]` - extras like `-i <inventory>`, `-u <user>`, `--become`
  (escalate to sudo).

Real examples from `adhoc_output.txt`:

```
ansible localhost -m ping
ansible localhost -m file -a "path=/tmp/ansible_test state=directory mode=0755"
ansible localhost -m command -a "uptime"
ansible localhost -m shell -a "echo $HOME && whoami"
ansible localhost -m copy -a "src=/tmp/test_source.txt dest=/tmp/test_dest.txt"
ansible localhost -m get_url -a "url=https://www.google.com dest=/tmp/google.html"
ansible localhost -m apt -a "name=curl state=present update_cache=yes" --become
```

The last one cannot run on this Arch box (no apt) - that is why the script
guards it and writes "Skipped no sudo access" as the result.