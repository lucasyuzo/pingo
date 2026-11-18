# pingo

pingo keeps a list of local repositories so you can jump to them (and keep them up to date) from any shell.

## Language

**Repository**:
A local directory registered in pingo's list, identified by its position, its alias, or its directory name.
_Avoid_: Project, entry, repo

**Alias**:
An optional short name given to a Repository, used instead of its directory name.
_Avoid_: Nickname, label

**Default branch**:
The branch a Repository's remote declares as its main line of development (usually `main` or `master`).
_Avoid_: Main branch, principal branch, trunk

**Pull**:
Bringing a Repository's Default branch up to date with its remote by fast-forward only, without changing the branch currently checked out.
_Avoid_: Update, sync

**Update**:
Upgrading pingo itself to its latest version.
_Avoid_: Upgrade, self-update
