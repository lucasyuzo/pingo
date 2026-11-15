# Changelog

All notable changes to this project are documented here.
This project follows [Semantic Versioning](https://semver.org/).

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
