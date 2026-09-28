# Installation Notes

## 1. Why do we use `pip install --user`?

`pip install --user` puts the package into the current user's own
directory (`~/.local/lib/pythonX.Y/site-packages` on Linux) and the
binaries into `~/.local/bin`. That means:

- no root permissions needed, no `sudo` at all;
- the system Python stays untouched - the default distro packages that
  depend on certain versions of libraries are not broken by a newer
  ansible;
- it is easy to remove later (`pip3 uninstall ansible`) without touching
  the system;
- the same user can test different setups in isolation.

It is the safest default path for a homework/learning environment and it
is exactly what the official Ansible installation docs recommend for
"installing on your own machine".

Note about this machine: Arch enables PEP 668 (externally-managed Python),
so `pip3 install --user ansible` alone is refused. The install script
retries with `--break-system-packages`, the officially documented override
flag - the packages still land user-local in `~/.local`, the system Python
stays untouched, and the flow is then byte-for-byte the PDF's `pip3
install --user` one.

## 2. What is the difference between installing with `apt` and `pip`?

|            | apt                                    | pip                             |
|------------|----------------------------------------|---------------------------------|
| source     | distro repository (Ubuntu/Debian)      | PyPI                            |
| version    | older, frozen by the distro release    | newest (or pinned by you)       |
| permissions| needs `sudo`                           | can be user-local (`--user`)    |
| upgrade    | follows distro cycle; usually LTS-only| `pip3 install --upgrade ansible` immediately |
| isolation  | system-wide, mixed with other pkgs     | user-local or venv, isolated    |

On Arch the equivalent of `apt` is `pacman`, and `pacman -S ansible` is of
course also possible - but the version stays tied to the repos. pip
trackcts the upstream releases and lets you roll back to an older pin if
a new major breaks a playbook.

## 3. Which method is better for production and why?

For production the recommended flow is **pip, but inside a virtual
environment** (or the pipx / venv pattern):

- a venv + a pinned `requirements.txt` means every deploy installs the
  exact same ansible-core and collection versions - reproducible;
- `pip install --user` on a production box can be polluted by other
  user-level tools, and a global system install risks breaking distro
  packages;
- moving to a dedicated control node/CI runner with `ansible-galaxy
  install -r requirements.yml` gives teams the same pinning for
  collections.

So the rule of thumb: local/lab -> `--user` is fine; anything serious ->
pip + venv with pinned versions (or an official container image), never
`apt`-frozen versions.