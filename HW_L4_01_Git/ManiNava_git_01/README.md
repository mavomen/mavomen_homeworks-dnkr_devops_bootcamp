# HW_L4_01_Git — Git Homework

Student: ManiNava  
Homework: HW_L4_01_Git  
Points: 33 (as stated in the PDF) / delivered in the structure the assignment asks for

## 1) Purpose

This submission captures the Git homework: installation/configuration, repository and commits, branching, merging and conflict resolution, stash, diff/history/time-travel with detached HEAD, reset/revert/restore, and a GitHub-style remote workflow (clone, pull, conflict, push). Every command used by the builders is recorded in `git_commands_log.txt` / `commands_history.txt`.

## 2) Structure

```text
ManiNava_git_01/
├── README.md
├── overview_qa.txt
├── commands_history.txt
├── git_commands_log.txt        # PDF name (identical to commands_history.txt)
├── final_structure.txt
├── run_all.sh                 # rebuilds everything from scratch
├── lib/common.sh
├── 01_basics/ 02_commits/ 03_branching/ 04_merging/ 05_stash/ 06_diff_history/ 07_reset_revert/ 08_github/
└──   (per-section build.sh + output .txt/.md + working repos with no nested .git tracked)
```

## 3) What each section contains

| Section | Focus | Evidence produced |
|---|---|---|
| `01_basics` | Install, identity, `git config --list` | `config_output.txt`, `status_after_add.txt`, `log_oneline.txt`, `my_project/` repo |
| `02_commits` | `add/commit`, working dir vs staging vs repo, `--amend` | `status_stages.txt`, `diff_outputs.txt`, `amend_log_before_after.txt`, `commit_demo/`, `amend_demo/` |
| `03_branching` | `branch`, `checkout`/`switch`, rename/delete, moving branches | `branch_log_graph.txt`, `branch_mgmt.txt`, `branch_demo/`, `branch_management/` |
| `04_merging` | Fast-forward, three-way merge (no conflict), real conflict + resolution | `ff_merge_log.txt`, `no_conflict_log.txt`, `conflict_before_after.txt`, the three repos |
| `05_stash` | `stash push -u`, `list/show/apply/pop/drop/clear` | `stash_list_show.txt`, `stash_demo/`, `stash_demo2/` |
| `06_diff_history` | `diff`/`diff --staged`/`diff HEAD`, branches/commits, detached HEAD | `diff_types.txt`, `detached_head.txt`, `diff_demo/`, `time_travel/` |
| `07_reset_revert` | `restore --staged`/`restore`, `reset --soft/mixed/hard`, `revert` | `reset_log_status.txt`, `revert_log.txt`, `reset_demo*`, `revert_demo/` |
| `08_github` | Local bare repo as `origin`, SSH/remote, `push`, clone + pull, conflict + resolve + push | `remote_branchvv.txt`, `pull_push.txt`, `collab_status.txt`, `github_demo/`, `collaboration/`, `pusher/` |

## 4) How to rebuild

From the submission root:

```bash
cd ManiNava_git_01
bash run_all.sh
```

The script creates a scratch work tree under `~/hw_l4_git_work/ManiNava_git_01/` (with full `.git` history for verification), regenerates `git_commands_log.txt` and `commands_history.txt`, copies working files (no `.git`) into the tracked section dirs, and refreshes the evidence files.

## 5) Notes about this environment

- **Git identity:** the delivered `01_basics/config_output.txt` shows the real global config of this machine (`mavantgarderc` / `manihabibinava@gmail.com`). Repos created by the builders use a local identity (`ManiNava` / `manihabibinava@gmail.com`) to keep evidence self-contained.
- **Global `pull.rebase = true`:** §8 would rebase on pull by default, so `git config pull.rebase false` is set per repository in the collaboration demo, and `git pull --no-rebase` semantics are exercised.
- **Remote used:** a local bare repo is used as `origin` for sections 8.1 and 8.2. The commands mirror the GitHub workflow (remote add/set-url, `branch -M main`, `push -u`, clone, pull, conflict resolution, push). To push to a real GitHub repo later, use `git remote set-url origin git@github.com:<user>/<repo>.git` (SSH is already authenticated on this machine).
- **Detached HEAD:** demonstrated with `git checkout HEAD~1` and saving work via `git branch from-detached` before returning to `main`.
- **Stash:** `git stash push -u` was used where safe; behavior with untracked files is documented in `05_stash/stash_explanation.md` (written separately).
- **Nested repos:** working trees are tracked without `.git` so the outer `homeworks` repo stays clean of nested repositories. The full repos including `.git` are shipped inside `ManiNava_git_01.zip`.
- **Sanitization:** outputs were scanned for tokens/credentials before packaging.
