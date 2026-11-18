# Changelog

All notable changes to this project are documented here.
This project follows [Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-11-18

### Added
- `pingo pull`: brings the default branch of every repository up to date with its remote, in list order, with one line per repository and a summary. Exits `1` only if a repository failed.
- `pingo pull <n|alias>` pulls a single repository; `pingo pull .` pulls the registered repository containing the current directory (deepest match wins). Both exit `1` if that repository failed or was skipped.
- Pull is fast-forward only and never changes the checked-out branch, the working tree or the shell's directory; it never merges, rebases, stashes or creates commits. Git prompts are disabled, so a remote needing credentials fails instead of hanging.
- Default branch discovery (remote HEAD, then `main`, then `master`) and remote selection (upstream, then `origin`).
- Repositories that can't be pulled safely are skipped with a reason (missing, not git, no remote, no default branch, uncommitted changes, merge/rebase in progress, default branch in another worktree); failures report diverged, remote unreachable, authentication required or git error.
- Menu keys `p` (pull the selected repository, result in the message line) and `P` (pull every repository, then back to the menu), shown in the footer and the help screen.
- Tab completion for `pingo pull` (aliases, folder names and `.`), and every Pull message in English and Brazilian Portuguese.

### Changed
- `pull` is now a pingo command and a reserved word for aliases. If you already have a repository aliased `pull`, `pingo pull` now runs the command instead of jumping to it; that repository is still reachable by position (`pingo <n>`) and from the menu, and you can give it a new alias with `pingo rename`.

## [0.1.0] - 2026-11-15

### Added
- `pingo` shell function for zsh and bash (macOS, Linux and Git Bash on Windows), written with shell builtins only.
- Interactive menu: arrow keys / `j` `k`, Enter to go, digits to jump, `a` add, `d` remove, `m` move, `r` rename, `s` settings, `?` help.
- Commands: `ls`, `add`, `rm`, `mv`, `rename`, `prune`, `config`, `config lang`, `update`, `help`, `--version`.
- Current git branch shown for each repository (read from `.git/HEAD`, no `git` call).
- English and Brazilian Portuguese; custom languages in `~/.config/pingo/lang/`.
- Windows path support (`C:\...`, `C:/...`, `/c/...`).
- Tab completion for zsh and bash.
- `install.sh` / `uninstall.sh`, interactive or with flags.
- Test suite running under bash 3.2, bash 5 and zsh; CI on Linux, macOS and Windows.
