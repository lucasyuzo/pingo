# Roadmap

Ideas planned for future versions. Suggestions are welcome in the issues.

## Default IDE per repository
Register an editor for each repository (e.g. `code`, `idea`, `nvim`) so pingo
can jump to the repository **and** open it in the right IDE.

- `pingo add <path> [alias] --ide code`
- `pingo ide <n|alias> <command>`
- In the menu: a key (e.g. `o`) to go and open the IDE.
- A global default IDE in the settings screen.

## Update the main branch
Update the main branch of every registered repository, or of a single one.

- `pingo pull` — every repository
- `pingo pull <n|alias>` — a single repository
- Detect the default branch (`main`/`master`), skip repositories with
  uncommitted changes, and show a summary at the end.
