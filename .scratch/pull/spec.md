# Spec: Pull the Default branch of registered Repositories

Status: ready-for-agent

## Problem Statement

My daily flow on any Repository is always the same: jump to it, bring its Default branch up to date with the remote, cut a new branch, and start a coding session (Claude, Devin). pingo already solves the jump. Bringing the Default branch up to date is still manual and fiddly: I have to remember whether the Repository uses `main` or `master`, stash or switch away from whatever branch I'm on, pull, and switch back. Across many Repositories, keeping every Default branch fresh is tedious enough that I simply don't do it, and I end up branching from stale code.

## Solution

A new **Pull** operation in pingo: it brings a Repository's Default branch up to date with its remote, by fast-forward only, **without changing the branch currently checked out** and without ever creating commits or rewriting history.

- `pingo pull` pulls every registered Repository, in list order, and prints one progress line per Repository followed by a summary.
- `pingo pull <n|alias>` pulls a single Repository.
- `pingo pull .` pulls the registered Repository that contains the current directory.
- In the interactive menu, `p` pulls the selected Repository in place, and `P` pulls every Repository, then returns to the menu.

Repositories that can't be pulled safely (missing, not git, local changes on the Default branch, etc.) are skipped with a reason, never touched.

## User Stories

1. As a developer, I want to run `pingo pull <alias>`, so that the Default branch of that Repository is up to date before I cut a new branch.
2. As a developer, I want to run `pingo pull .` right after `pingo <alias>`, so that I can pull the Repository I just jumped to without typing its alias again.
3. As a developer, I want `pingo pull .` to work from any subdirectory of a registered Repository, so that I don't need to be at its root.
4. As a developer, I want `pingo pull .` to fail with a clear message when the current directory isn't inside any registered Repository, so that I know nothing happened.
5. As a developer, I want to run `pingo pull` with no arguments, so that every registered Repository's Default branch is brought up to date in one go.
6. As a developer, I want `pingo pull <n>` to accept a position, so that it resolves Repositories exactly like `pingo <n>` does.
7. As a developer working on a feature branch, I want Pull to update the Default branch without checking it out, so that my current branch and working tree are untouched.
8. As a developer with uncommitted changes on a feature branch, I want Pull to still update the Default branch, so that local work in progress never blocks it.
9. As a developer whose checkout is the Default branch, I want Pull to fast-forward it in place, so that my working tree reflects the latest remote state.
10. As a developer with tracked uncommitted changes on the Default branch, I want that Repository skipped with "uncommitted changes", so that pingo never risks my work.
11. As a developer with a merge or rebase in progress on the Default branch, I want that Repository skipped, so that pingo never interferes with an operation I'm in the middle of.
12. As a developer with only untracked files on the Default branch, I want Pull to proceed, so that stray files don't block updates (git itself refuses if it would overwrite one).
13. As a developer whose local Default branch has commits the remote doesn't, I want Pull to report the Repository as "diverged" (failed), so that I know I must resolve it myself.
14. As a developer, I want Pull never to merge, rebase, or create commits, so that it's always safe to run.
15. As a developer with a detached HEAD, I want Pull to update the Default branch without touching my checkout, so that detached work is preserved.
16. As a developer using git worktrees, I want a Repository whose Default branch is checked out in another worktree to be skipped with a clear reason, so that I understand why it wasn't pulled.
17. As a developer, I want pingo to discover the Default branch from what the remote declares, falling back to `main` and then `master`, so that I don't have to configure it.
18. As a developer whose Repository has no identifiable Default branch, I want it skipped with "no Default branch found", so that the run continues.
19. As a developer, I want Pull to use the Default branch's configured upstream remote, falling back to `origin`, so that forks and unusual setups behave correctly.
20. As a developer whose Repository has no remote, I want it skipped with "no remote", so that the run continues.
21. As a developer, I want missing directories and non-git directories skipped (not failed), so that a stale list doesn't make the whole run look broken.
22. As a developer, I want each updated Repository to show how many commits it received and the old → new short hashes, so that I can see what changed at a glance.
23. As a developer, I want Repositories that were already current reported as "already up to date", so that I can tell them apart from skipped ones.
24. As a developer, I want a summary at the end of `pingo pull` counting updated, already up to date, skipped, and failed Repositories, with the reason for each skip or failure, so that I can act on problems.
25. As a developer scripting pingo, I want `pingo pull` to exit `1` only when at least one Repository failed, so that skips (expected states) don't break scripts.
26. As a developer scripting pingo, I want `pingo pull <n|alias|.>` to exit `1` when that Repository failed or was skipped, so that I know my explicit request wasn't fulfilled.
27. As a developer pulling a single Repository, I want just its result line without a summary block, so that the output stays short.
28. As a developer, I want `pingo pull <alias>` to leave my current directory unchanged, so that pulling and jumping stay separate operations.
29. As a developer whose remote needs credentials, I want Pull to fail that Repository instead of hanging on a password prompt, so that a pull-all run never stalls.
30. As a developer using SSH keys loaded in an agent, I want Pull to keep working normally, so that disabling interactive prompts doesn't break my setup.
31. As a developer offline or with a broken remote, I want that Repository reported as failed with the reason, and the run to continue with the next one.
32. As a developer, I want Pull to fetch only the Default branch, so that pulling many Repositories is fast.
33. As a developer without git installed, I want `pingo pull` (and `p`/`P`) to fail immediately with the same message `pingo update` uses, so that the problem is obvious.
34. As a developer in the menu, I want to press `p` to Pull the selected Repository and see "pulling <name>…" and then the result in the message line, so that I never leave the menu.
35. As a developer in the menu, I want to stay on the same selection after `p`, so that I can press Enter to jump right after pulling.
36. As a developer in the menu, I want to press `P` to Pull every Repository with the same progress and summary as the CLI, then press Enter to return to the menu, so that I can refresh everything without leaving pingo.
37. As a developer, I want `P` to start without a confirmation prompt, so that a non-destructive action stays quick.
38. As a developer, I want `p` and `P` listed in the menu footer/help screen and `pingo pull` in `pingo help`, so that I can discover them.
39. As a developer, I want tab completion for `pingo pull <TAB>` to offer aliases, names, and `.`, so that I type less.
40. As a Portuguese-speaking developer, I want every Pull message available in pt-BR, so that the experience matches the rest of pingo.
41. As a developer who already has a Repository aliased `pull`, I want the `pull` command to take precedence and that Repository to stay reachable by position and from the menu, with the change noted in the CHANGELOG, so that nothing silently breaks.
42. As a developer, I want `pull` rejected as a new alias, so that the command and an alias can never collide again.
43. As a developer, I want "update" to keep meaning only "upgrade pingo itself", so that `pingo update` and `pingo pull` are never confused.

## Implementation Decisions

- **Vocabulary** follows `GLOSSARY.md`: the operation is **Pull**, the target is the **Default branch** of a **Repository**. "Update" stays reserved for upgrading pingo itself; avoid "update"/"sync" for this feature in code identifiers, messages, help, and docs.
- **New command `pull`** in the main dispatcher, with forms: no argument (all), `<n|alias>` (resolved exactly like navigation, reusing the existing resolution logic), and `.` (the registered Repository whose path contains the current directory; deepest match wins if Repositories are nested). Extra arguments → usage error (exit `2`), like other commands.
- **`pull` becomes a reserved word** for aliases and is added to the completion command words. No migration of an existing `pull` alias; the command wins.
- **Default branch discovery**, in order: the remote's declared HEAD (`refs/remotes/origin/HEAD`); else a local `main`; else a local `master`; else skip with "no Default branch found". No per-Repository override in this version.
- **Remote selection**: the Default branch's configured upstream remote; else `origin`; else skip with "no remote".
- **Pull mechanics** (fast-forward only, never changes checkout, fetches only the Default branch):
  - Checkout is **not** the Default branch (including detached HEAD): fetch the remote's Default branch directly into the local Default branch ref (`<remote> <db>:<db>`), which git only accepts as a fast-forward.
  - Checkout **is** the Default branch: fast-forward-only pull of that branch from the remote.
  - Never merge, rebase, stash, checkout, or create commits.
- **Pre-checks that skip** (pingo does not attempt the Pull): directory missing; not a git repository; no remote; no Default branch; checkout is the Default branch and there are tracked uncommitted changes (staged or unstaged) or a merge/rebase in progress; Default branch checked out in another worktree. Untracked files never cause a skip.
- **Failures** (pingo attempted and git refused or errored): diverged (not a fast-forward), network, authentication, any other git error. The reason is shown in a short, translated form.
- **Result categories**: updated (with commit count and old → new short hashes), already up to date, skipped (reason), failed (reason).
- **Git invocation** runs with interactive terminal prompts disabled (`GIT_TERMINAL_PROMPT=0`), so credential prompts fail instead of hanging. SSH agent auth is unaffected.
- **Git availability**: if `git` isn't on `PATH`, Pull fails immediately with the existing "git not found" message used by `pingo update`.
- **Execution**: sequential, in list order, one progress line per Repository.
- **Output and exit codes**:
  - `pingo pull` (all): progress lines + summary block. Exit `1` iff at least one failed; skips don't count.
  - `pingo pull <n|alias|.>`: only that Repository's result line, no summary. Exit `1` if failed **or** skipped.
  - Pull never changes the shell's current directory.
- **Menu**:
  - `p`: pulls the selected Repository inside the TUI; the message line shows a "pulling <name>…" indicator then the result. The selection is kept.
  - `P`: leaves the alternate screen, runs the same flow and output as `pingo pull`, waits for Enter, then returns to the menu.
  - No confirmation for either. Both appear in the menu footer and the help screen key list.
- **Single Pull core**: one internal routine pulls one Repository and returns its category + detail. The CLI (single and all), `p`, and `P` all build on it; only presentation differs.
- **i18n**: every new message has keys in both `en` and `pt-BR` language files.
- **Docs and release**: `pingo help` gains the `pull` line; READMEs (en and pt-BR) document the command and the `p`/`P` keys; CHANGELOG gets a new version entry (including the `pull` alias note); the "Update the main branch" item is removed from the ROADMAP. Version bumps to **0.2.0**.

## Testing Decisions

- **Good tests exercise external behavior only**: invoke the public `pingo` function (or drive the menu with keys) and assert on output, exit status, and the **real git state** afterwards (where the Default branch points, which branch is checked out, whether the working tree is unchanged). Internal `_pingo_*` helpers are not tested directly, and `git` is never mocked.
- **Seams** (both already exist):
  1. The `pingo` function as the public API, as in the core command tests.
  2. The menu driven by a key file, as in the menu tests (`p`, `P`, then return/quit).
- **New fixture** in the test helper library: create a local bare remote, clone it into a working Repository, and advance the remote by N commits from a separate clone. No network. Must work under bash ≥ 3.2 and zsh (the test runner covers all shells), and must set a local git identity so commits work on clean machines/CI.
- **Scenarios to cover**:
  - Fast-forward on the Default branch checkout; fast-forward while on a feature branch (feature branch and working tree untouched); detached HEAD.
  - Already up to date.
  - Each skip reason: missing directory, non-git directory, no remote, no Default branch, tracked changes on the Default branch, merge/rebase in progress, Default branch in another worktree.
  - Untracked files on the Default branch don't skip.
  - Diverged → failed; unreachable remote → failed; the run continues past a failure.
  - `main` vs `master` discovery and remote HEAD discovery; upstream remote vs `origin` fallback.
  - Summary counts and exit codes for all vs single; `pingo pull .` from root and from a subdirectory; `.` outside any Repository; unknown alias; extra arguments.
  - `pull` rejected as an alias; completion words include `pull`.
  - Menu `p` (message line, selection kept) and `P` (summary shown, returns to menu).
  - pt-BR messages, as in the i18n tests.
  - Git not on `PATH` → immediate failure.
- **Prior art**: the core command tests (add/rm/mv/rename/prune via `pingo …`), the menu tests (key file driving the TUI), and the i18n tests (language switching).

## Out of Scope

- Per-Repository Default branch override (e.g. `develop`); may come later alongside per-Repository IDE settings.
- Fetching all branches, `--prune`, or updating branches other than the Default branch.
- Merge, rebase, or stash-based updates for diverged or dirty Repositories.
- Parallel execution.
- Pulling and jumping in one command (`pingo pull <alias>` doesn't navigate).
- Automatic migration of an existing `pull` alias.
- Any timeout handling for slow remotes beyond what git itself provides.

## Further Notes

- This is pingo's first operation over registered Repositories that depends on the `git` binary and the network; everything else reads `.git` directly. Keep git calls confined to the Pull core.
- Must remain pure shell with zero dependencies, compatible with bash 3.2+, zsh, and Git Bash on Windows (path handling for worktrees already exists in the branch reader).
