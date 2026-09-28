# Ad-Hoc Commands - Best Practices

## 1. When should we use ad-hoc commands?

Use ad-hoc when the job is:

- **quick and one-time** - a temporary fix you want to apply right now on
  a few hosts (create a folder, restart a service, check disk space);
- **testing** - verifying connectivity (`ping`), inspecting facts
  (`setup`), trying a module's behaviour before writing a playbook;
- **troubleshooting** - "what is the uptime / who is logged in / is the
  file present" across a group.

They are perfect for *exploration and firefighting*, not for anything
that must be repeated or gatekept.

## 2. When should we write a playbook instead?

Write a playbook when the task:

- has **more than one step** (install + configure + restart);
- must be **reusable** (same deploy next week, or for another team);
- needs **order / dependencies / handlers / variables**;
- must be **reviewed and versioned** (pull request, audit trail);
- is part of the **infrastructure-as-code** baseline of the environment.

Rule of thumb from the assignment: ad-hoc = quick + one-off; playbook =
complex + reusable. If you find yourself running the same ad-hoc line for
the third time, it is time to promote it into a playbook.

## 3. Best practices for ad-hoc commands

- Keep them **read-only or reversible** unless you know exactly what you
  are doing - no surprise `apt remove` on a fleet;
- always pass an **inventory** explicitly (`-i inventory`) so the run
  targets what you think it targets;
- use `--become` only when the task really needs root, and never leave the
  become password in the command line (use `--ask-become-pass` or
  `ansible.cfg`);
- run against a **small pattern first** (`ansible web1 -m ping`) before
  `all`;
- use modules instead of `shell` whenever possible (`file`, `copy`,
  `get_url` are idempotent and safer);
- think about **quoting**: `-a "echo $HOME && whoami"` is expanded by
  your shell before ansible sees it, so be deliberate about `$` and
  quotes;
- results go to your screen only - if you need an audit trail, write the
  output to a file (exactly what `adhoc_output.txt` does) or use a
  playbook.