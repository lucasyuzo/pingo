<div align="center">

# 🐾 pingo

**Your faithful companion to jump between local repositories.**

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

  ⏎ open   a add   d remove   m move   s settings   ? help   q quit
```

Type `pingo`, pick a repository with the arrow keys, press Enter: you are there.
Or skip the menu entirely with `pingo api` or `pingo 2`.

## Features

- **Interactive menu** with arrow keys (or `j`/`k`), number jumps and shortcuts to add, remove, reorder and rename.
- **Direct jumps**: `pingo <alias>`, `pingo <folder-name>` or `pingo <position>`.
- **Your order**: the list is shown in the order you choose. Reorder with `m` in the menu or `pingo mv`.
- **Current branch** next to each repository, read straight from `.git/HEAD` (instant, even on Windows).
- **Missing repositories** are flagged in red; `pingo prune` cleans them up.
- **English and Português (Brasil)**, detected from your system. Add any other language with a single file.
- **Tab completion** in zsh and bash.
- **Pure shell**: only bash/zsh builtins. Works on zsh ≥ 5 and bash ≥ 3.2.

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
| `s`                      | settings (language)                            |
| `?`                      | help                                           |
| `q` / `Esc`              | quit                                           |

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

In Homer's *Odyssey*, after twenty years away, Odysseus returns to Ithaca
disguised as a beggar. Nobody recognizes him — except **Argos**, his old dog,
who knows him at once. Like Argos, pingo always remembers the way back home,
to every one of your repositories.

## License

[MIT](LICENSE)
