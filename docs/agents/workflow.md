# Workflow

How a change to pingo travels from idea to release.

## Setup

Enable the repo's git hooks once per clone (worktrees share it):

```
git config core.hooksPath .githooks
```

`commit-msg` enforces the commit subject format and `pre-commit` keeps `main` merge-only; `tests/test_hooks.sh` covers both.

## Feature flow

A feature goes through the engineering skills in order, leaving its record in the repo:

1. `/grill-with-docs` on the ROADMAP item: settles decisions and updates `GLOSSARY.md`.
2. `/to-spec`: writes `.scratch/<feature>/spec.md`.
3. `/to-tickets`: writes `.scratch/<feature>/issues/NN-<slug>.md`.
4. `/implement-spec`: builds the tickets on the integration branch, then code review and fixes.

Small fixes and docs changes go straight to a branch.

**Interface contracts.** When a ticket creates an interface other tickets consume (function names, return variables, result values, message keys), that ticket's file names the contract, and every consuming ticket points to it. Tickets running in parallel build against the written contract.

## Branches

Every change starts on a branch cut from `main`:

| Branch | For |
|---|---|
| `feat/<slug>` | a feature; the **integration branch** for its spec |
| `ticket/NN-<slug>` | one ticket, cut from the integration branch and merged back into it |
| `fix/<slug>` | a bug fix, or the code-review fixes of a feature |
| `docs/<slug>` / `chore/<slug>` | docs or tooling only |

Check out the integration branch before dispatching ticket agents, so their worktrees start from it. Merge ticket and fix branches into the integration branch (fast-forward when possible) and delete them once merged.

## Commits

Conventional Commits written in Portuguese, verb in the present third person (`feat: pingo pull traz a Default branch em dia com o remoto`, `fix(menu): q e Esc também voltam ao menu depois do P`).

- One logical change per commit, with its tests in the same commit; `tests/run.sh` passes before each one.
- Use the GLOSSARY vocabulary (Repository, Default branch, Pull; "update" is only pingo's self-update).
- Agent-authored commits end with the agent's `Co-Authored-By:` trailer.

## Closing tickets

When the integration branch is complete, set every ticket and the spec to `**Status:** done`, tick their acceptance criteria, and commit it on the integration branch (`docs: marca a spec e os tickets de <feature> como concluídos`).

## Versions

Semantic Versioning: a feature bumps the minor, a fix bumps the patch (while in `0.x`, breaking changes also bump the minor). The release commit, on the branch, updates together:

- `PINGO_VERSION` in `pingo.sh` and a `## [X.Y.Z] - YYYY-MM-DD` entry in `CHANGELOG.md` (`Added` / `Changed` / `Fixed`), including any behaviour change that can surprise existing users; `tests/test_core.sh` fails when the two disagree;
- the delivered item removed from `ROADMAP.md`;
- both READMEs (`README.md` and `README.pt-BR.md` mirror each other).

## Merging into `main`

Merge with `git merge --no-ff -F <message-file>` (git merge reads the message from a file, not stdin), so the branch's commits stay grouped under one merge commit. The merge message is the change's record in history:

```
Merge feat/<slug>: <one-line summary> (vX.Y.Z)

<what the change does, from the user's point of view>

Contexto e decisões:
- Glossário: GLOSSARY.md
- Spec: .scratch/<feature>/spec.md
- Tickets: .scratch/<feature>/issues/
```

Run `tests/run.sh` on `main` after the merge.

## Tags and publishing

Each release is an annotated tag on its merge commit: `git tag -a vX.Y.Z <merge> -m "pingo vX.Y.Z — <summary>"`.

Pushing `main` publishes to every user, because `pingo update` pulls `main`. Push `main` and its tag together (`git push origin main vX.Y.Z`) only after the user's explicit go-ahead, then delete the merged local branch.
