# Idempotency & State Management Explanation

## 1. What is Idempotency?

Definition: an operation is **idempotent** if running it many times
produces the **same end result** as running it once. In Ansible terms: a
task that creates a directory creates it on the first run and does
*nothing* on the second run (the directory already exists in the desired
state).

Why it matters:

- **Security** - re-runs never introduce errors or destructive side
  effects (no double-installs, no duplicate users, no overwritten files);
- **Reliability** - you can run the same playbook 100 times and the
  machine stays in the same correct state;
- **Debugging** - easy to spot what actually changed on each run
  (`changed: true` vs `changed: false`), which isolates problems.

Practical examples:

- installing a package: if already installed, it is not reinstalled;
- creating a file: if it exists, it is not recreated from scratch;
- starting a service: if it is running, it is not started again.

## 2. State Management

Ansible follows a **state-based approach**: instead of telling the tool
*how* to act (`install the package, then edit the config, then restart`),
you declare the **desired state** and the module decides what to do:

- `state: present` for a package - instead of "install";
- `state: directory` for a path - instead of "create folder";
- `state: started` for a service - instead of "start it".

You define the *state*, not the *actions*. Benefits:

- idempotency comes automatically - the module only acts if the current
  state differs from the desired one;
- better readability - a playbook reads like a description of the target,
  not like a step-by-step shell script;
- easier maintenance - changing a requirement is editing one line of the
  desired state, wherever the machine currently is.

## 3. How does Ansible guarantee Idempotency?

The modules enforce it: before making any change, a module **checks the
current state** on the target and **only changes what differs from the
desired state**:

- no change needed -> the task reports **`changed: false`** (blue) - fine;
- something was modified -> reports **`changed: true`** (yellow).

So the guarantee is not by convention but by design: `file`, `apt`,
`service`, `copy`... all read first, act second, and clearly report what
they did. The demo below (`idempotency_demo.txt`) shows exactly that - the
first `file` run created `/tmp/ansible_idempotency` (`changed: true`),
while the second and third runs reported `changed: false` because the
directory already existed.