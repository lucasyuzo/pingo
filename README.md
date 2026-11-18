<div align="center">

<img src="assets/pingo.png" alt="Pingo, a cocker spaniel, licking his nose" width="160">

# 🐾 pingo

**Your faithful companion to find local repositories.**

Pure shell · zero dependencies · zsh & bash · macOS, Linux and Windows (Git Bash)

[Português](README.pt-BR.md) · [Roadmap](ROADMAP.md) · [Changelog](CHANGELOG.md)

</div>

```
  pingo  · 5 repositories

  ❯ 1  api       ~/work/api           ⎇ main
    2  web       ~/work/web-frontend  ⎇ feat/login
    3  infra     ~/work/infra         ⎇ develop
    4  dotfiles  ~/dotfiles           ⎇ master
    5  old-proj  ~/old/proj           ✗ not found

  ⏎ open   a add   d remove   m move   p pull   P pull all   s settings   ? help   q quit
```

Type `pingo`, pick a repository with the arrow keys, press Enter: you are there.
Or skip the menu entirely with `pingo api` or `pingo 2`.

## Features

- **Interactive menu** with arrow keys (or `j`/`k`), number jumps and shortcuts to add, remove, reorder and rename.
- **Direct jumps**: `pingo <alias>`, `pingo <folder-name>` or `pingo <position>`.
- **Your order**: the list is shown in the order you choose. Reorder with `m` in the menu or `pingo mv`.
- **Pull**: `pingo pull` brings the default branch of every repository up to date with its remote, fast-forward only, without changing the branch you have checked out (`p`/`P` in the menu).
- **Current branch** next to each repository, read straight from `.git/HEAD` (instant, even on Windows).
- **Missing repositories** are flagged in red; `pingo prune` cleans them up.
- **English and Português (Brasil)**, detected from your system. Add any other language with a single file.
- **Tab completion** in zsh and bash.
- **Pure shell**: only bash/zsh builtins. Works on zsh ≥ 5 and bash ≥ 3.2.
  (`pingo pull` and `pingo update` call `git`, which must be installed.)

## Install

pingo is installed by cloning the repository and running the installer, which
adds **one line** to your shell startup file.

```sh
git clone https://github.com/lucasyuzo/pingo ~/.pingo
~/.pingo/install.sh
```

The installer asks where pingo should be loaded and suggests the right file for your shell:

| Option            | When to use it                                                           |
|-------------------|--------------------------------------------------------------------------|
| `~/.zshrc`        | zsh (macOS default)                                                      |
| `~/.bash_profile` | bash on **Windows (Git Bash)** and macOS, which open login shells        |
| `~/.bashrc`       | bash on Linux. pingo also makes sure `~/.bash_profile` loads `~/.bashrc` |

Then open a new terminal (or `source` the file) and register your first repository:

```sh
pingo add ~/work/api        # alias defaults to the folder name
pingo add . web             # current directory, with the alias "web"
pingo                       # open the menu
```

<details>
<summary>Non-interactive install (scripts, CI, team setup)</summary>

```sh
~/.pingo/install.sh --rc ~/.zshrc --lang pt-BR --yes
```

| Flag            | Description                                              |
|-----------------|----------------------------------------------------------|
| `--rc <file>`   | startup file that loads pingo                            |
| `--lang <code>` | interface language (default: detected from your system) |
| `-y`, `--yes`   | use the defaults, ask nothing                            |

</details>

<details>
<summary>Why a line in my rc file instead of a binary in the PATH?</summary>

A program in your `PATH` runs in a child process: it can change *its own*
directory, but never the directory of the shell you are typing in. That's why
directory jumpers (nvm, zoxide, autojump…) are shell **functions** loaded from
your startup file. Using pingo feels exactly like using a command.

</details>

## Usage

| Command                          | Description                                  |
|----------------------------------|----------------------------------------------|
| `pingo`                          | open the interactive menu                    |
| `pingo <n\|alias>`               | go straight to a repository                  |
| `pingo ls`                       | list repositories                            |
| `pingo add <path> [alias]`       | register a repository (at the end)           |
| `pingo rm <n\|alias> [-y]`       | remove a repository from the list            |
| `pingo mv <n\|alias> <position>` | move a repository to another position        |
| `pingo rename <n\|alias> <new>`  | change the alias                             |
| `pingo prune`                    | remove repositories that no longer exist     |
| `pingo config`                   | show settings and file locations             |
| `pingo config lang [code]`       | list languages or change the language        |
| `pingo pull`                     | pull every repository (see [Pull](#pull))    |
| `pingo pull <n\|alias>`          | pull a single repository                     |
| `pingo pull .`                   | pull the repository you are in               |
| `pingo update`                   | update pingo (`git pull` in the install dir) |
| `pingo help`, `pingo --version`  | help and version                             |

### Menu keys

| Key                      | Action                                         |
|--------------------------|------------------------------------------------|
| `↑` `↓` / `j` `k`        | navigate (`Home`/`End`, `g`/`G` also work)     |
| `Enter`                  | go to the selected repository                  |
| `1`–`9`                  | jump to a position                             |
| `a`                      | add the current directory                      |
| `d`                      | remove the selected repository (asks first)    |
| `m`                      | move: pick it up, use `↑` `↓`, drop with Enter |
| `r`                      | rename (change alias)                          |
| `p`                      | pull the selected repository                   |
| `P`                      | pull every repository, then back to the menu   |
| `s`                      | settings (language)                            |
| `?`                      | help                                           |
| `q` / `Esc`              | quit                                           |

### Pull

`pingo pull` brings the **default branch** of a repository (the branch its
remote declares as the main line, usually `main` or `master`) up to date with
its remote. It's always safe to run:

- **Fast-forward only.** pingo never merges, rebases, stashes or creates commits.
  If your local default branch has commits the remote doesn't, it reports
  *diverged* and leaves it for you.
- **Never changes your checkout.** On a feature branch (or a detached HEAD), the
  default branch is updated without being checked out; your branch and working
  tree are untouched, even with uncommitted changes. If the default branch *is*
  checked out, it is fast-forwarded in place.
- **Never changes your directory.** `pingo pull api` doesn't jump to `api`.
- **Never hangs on a password prompt.** A remote that needs credentials fails
  instead (SSH keys in an agent keep working).

The default branch is the remote's declared HEAD, else a local `main`, else a
local `master`. The remote is the branch's upstream, else `origin`.

```sh
pingo pull          # every repository, in list order, then a summary
pingo pull api      # a single repository, by alias, folder name or position
pingo api && pingo pull .   # the registered repository you are in (any subdirectory)
```

Each repository gets one line: *updated* (with the number of commits and the
old → new hashes), *already up to date*, *skipped* or *failed*, with the reason:

| Skipped (nothing was touched)                           | Failed (git refused or errored) |
|---------------------------------------------------------|---------------------------------|
| directory not found                                     | diverged                        |
| not a git repository                                    | remote unreachable              |
| no remote                                               | authentication required         |
| no default branch found                                 | git error                       |
| uncommitted changes (on the checked-out default branch) |                                 |
| merge / rebase in progress                              |                                 |
| default branch checked out in another worktree          |                                 |

Untracked files never cause a skip. `pingo pull` exits `1` only if a repository
failed (skips are expected states); `pingo pull <n|alias|.>` exits `1` if that
repository failed **or** was skipped.

### Aliases and paths

- An alias is optional. Without one, the repository shows its folder name, and
  `pingo <folder-name>` works as long as that name is unique.
- Aliases can't be only digits (numbers are positions), contain spaces or `|`,
  start with `-`, or be a pingo command.
- The same directory can't be registered twice.
- On Windows you can use `C:\Users\me\api`, `C:/Users/me/api` or `/c/Users/me/api`;
  pingo stores them all the same way.

## Configuration

Everything lives in `~/.config/pingo/` (or `$XDG_CONFIG_HOME/pingo/`):

| File       | Content                                                   |
|------------|-----------------------------------------------------------|
| `repos`    | one repository per line, `alias\|path`, in display order |
| `config`   | settings, `key=value` with comments                       |
| `lang/`    | your own translations (optional)                          |

Both files are plain text and can be edited by hand.

### Language

The installer picks the language from your system (`$LANG` on macOS/Linux,
the Windows locale on Git Bash). Change it whenever you want:

- press `s` in the menu, or
- run `pingo config lang pt-BR`, or
- edit `lang=` in `~/.config/pingo/config`.

#### Adding a language

1. Copy [`lang/en.sh`](lang/en.sh) to `~/.config/pingo/lang/<code>.sh` (e.g. `es.sh`).
2. Translate the strings (keep each `%s`).
3. Run `pingo config lang <code>`.

Untranslated keys fall back to English, so a partial translation works fine.
Pull requests with new languages are very welcome!

## Uninstall

```sh
~/.pingo/uninstall.sh        # asks whether to delete your list and settings
rm -rf ~/.pingo              # remove the program files
```

`--yes` keeps your data without asking; `--purge` deletes it.

## Development

```sh
tests/run.sh                 # runs every test under bash, zsh and (on macOS) bash 3.2
SHELLS="zsh" tests/run.sh    # a single shell
```

CI runs the suite on Linux, macOS and Windows (Git Bash) on every push.

## Why "pingo"?

Pingo is the name of my dog. 🐕

Pingo is a cocker spaniel, and cocker spaniels were born with a nose that
should honestly be illegal. Drop a crumb in the kitchen and he finds it before
it lands. Hide a treat at the back of the closet and he's already sitting in
front of the door, staring at you.

This tool works the same way, minus the drool: tell it where you want to go and
it sniffs the repository out for you. No `cd ../../../where/was/it/again`. No
digging through folders. Just `pingo`, Enter, and you're there.

Good boy. 🦴

## License

[MIT](LICENSE)
