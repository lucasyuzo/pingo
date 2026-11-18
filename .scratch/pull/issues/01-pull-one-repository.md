# 01: Pull one Repository (tracer bullet)

**What to build:** `pingo pull <n|alias>` brings that Repository's Default branch up to date with its remote, fast-forward only, without changing the branch checked out. This is the happy path end to end and establishes the single Pull core that every later ticket builds on (see spec: Implementation Decisions → "Single Pull core", "Pull mechanics", "Default branch discovery", "Remote selection").

Includes a small prefactor first: extract the "git must be installed" check currently inside `pingo update` into a shared helper, and reuse it for Pull.

Also introduces the test fixture from the spec's Testing Decisions (local bare remote, a clone of it, and a way to advance the remote by N commits; local git identity; no network; bash 3.2+ and zsh).

**Blocked by:** None (can start immediately)

**Status:** done

- [x] `pingo pull <alias>` and `pingo pull <n>` resolve the Repository exactly like navigation; unknown alias/position fails with the existing resolution error
- [x] Checkout is the Default branch → fast-forwarded in place; working tree reflects the new commits
- [x] Checkout is a feature branch → Default branch ref advances; checkout, feature branch, and working tree (including uncommitted changes) are untouched
- [x] Detached HEAD → Default branch ref advances; HEAD unchanged
- [x] Default branch discovered from the remote's declared HEAD, else local `main`, else local `master`
- [x] Remote is the Default branch's upstream, else `origin`
- [x] Only the Default branch is fetched
- [x] Result line shows "updated" with commit count and old → new short hashes, or "already up to date"; exit `0`
- [x] Git runs with terminal prompts disabled
- [x] Without `git` on `PATH`, fails immediately with the same message as `pingo update`
- [x] Extra arguments → usage error, exit `2`
- [x] `pingo pull` does not change the shell's current directory
- [x] `pull` is rejected as a new alias and offered by tab completion as a command word
- [x] `pingo help` lists `pingo pull [n|alias]`
- [x] All new messages exist in `en` and `pt-BR`
- [x] Tests pass under every shell in the test runner
