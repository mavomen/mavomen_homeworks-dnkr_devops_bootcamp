# Loops & Conditionals - notes for 1.2

`conditionals_loops.yml` puts the two control-flow tools side by side.

## `loop` - do the same task many times

- The list lives in `vars:` (`packages`, `users`) and the task iterates it
  with `loop:`. Inside the task the current element is `{{ item }}`.
- Two shapes are used in this playbook:
  - a list of plain strings - `loop: "{{ packages }}"` then
    `name: "{{ item }}"`;
  - a list of dicts - `loop: "{{ users }}"` then `item.name` and
    `item.state`, which is why `user1` and `user2` are only written once.
- The run log repeats the task name once per item
  (`item=curl`, `item=wget`, `item=git`) and reports `ok` / `changed` for
  each one separately, so a failure on item 2 does not hide item 3.

## `when` - run a task only if it makes sense

- Comparison operators: `==`, `!=`, `>`, `<`, and they can be mixed in a
  list, in which case **all** of them must be true (that is an implicit
  `and`).
- The first example is a platform guard:
  `when: ansible_os_family == "Debian"`. I am on Arch, so those three
  package tasks are reported as `skipping` in the log instead of trying
  to call apt - that is the condition doing its job.
- The last task lists two conditions
  (`ansible_distribution == "Ubuntu"` and `ansible_memtotal_mb > 1024`);
  my box has enough RAM but is not Ubuntu, so the task is skipped. Both
  halves of the `and` have to pass.

## `register` + a conditional on the result

The `stat` task does not change anything, it only asks about the target
and stores the answer in `dir_check`:

    - name: Check directory
      stat:
        path: /opt/myapp
      register: dir_check

    - name: Create if not exists
      file:
        path: /opt/myapp
        state: directory
      when: not dir_check.stat.exists

So the second run of the same playbook (see `conditionals_loops_rerun.txt`)
reports `stat.exists: true` and the create task goes back to `ok` instead
of `changed` - check first, then act, is the pattern behind almost every
idempotent playbook.

## Small extra

`msg: "{{ 'Sufficient memory' if ansible_memtotal_mb > 1024 else 'Low memory' }}"`
is a Jinja2 expression inside a string: the same `if/else` idea as
`when:`, but evaluated while rendering the value. Handy for one line of
text, not for skipping a task.