# Module Usage Guide (ansible-doc)

## 1. How to use `ansible-doc`?

`ansible-doc` is the offline documentation tool shipped with ansible:

- `ansible-doc -l` - list all available modules (use `--list` too);
- `ansible-doc <module>` - full documentation for one module (NAME -
  SYNOPSIS - OPTIONS - EXAMPLES - RETURN VALUES);
- `ansible-doc -t module <module>` - same thing, but guarantees the
  module-type docs (the `-t` type can also select `callback`,
  `inventory_plugin`, `connection`...);
- useful pagination helpers: `ansible-doc <module> | less`, and combined
  filters like `ansible-doc -t module ping | grep -A 20 "EXAMPLES"`
  (exactly what `modules_documentation.sh` does).

Since it reads the locally installed modules, the output always matches
the version you actually have - no stale docs from a website.

## 2. How to find the examples?

In the module output, jump straight to the `EXAMPLES` section:

- `ansible-doc file | grep -A 15 "EXAMPLES"` - shows the example task
  blocks with real parameter names and values;
- or open the full doc (`ansible-doc file`) and scroll to EXAMPLES;
- inside the examples you can spot pattern usage (e.g. `mode: '0644'`,
  `owner: root`, `recurse: true`) that you can copy directly into
  `-a "..."` arguments or playbooks.

## 3. How to understand the parameters?

Each module doc lists `OPTIONS` with, per parameter:

- the name (e.g. `path`, `mode`, `state`);
- what type it takes (`str`, `int`, `bool`, `list`, `dict`);
- required or default value (**required** appears in the synopsis, the
  default is shown in the OPTIONS table);
- a short description of what the parameter does.

Examples of reading it: for `file`, `path` is required and `state` has a
default of `file` (so `state=directory` changes the meaning to "directory
mode"); for `apt`, `name` is a `str` and `update_cache` a `bool`
defaulting to `no` (`yes` triggers a repo refresh before installing).
Combine that with the EXAMPLES block and you can write correct module
arguments without ever touching a browser.