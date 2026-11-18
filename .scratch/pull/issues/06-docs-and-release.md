# 06: Docs and release 0.2.0

**What to build:** Users can discover and understand Pull from the docs, and the release is cut (see spec: "Docs and release").

**Blocked by:** 02, 03, 04, 05

**Status:** done

- [x] README (en) and README.pt-BR document `pingo pull`, `pingo pull <n|alias>`, `pingo pull .`, the `p`/`P` keys, and the fast-forward-only / never-changes-checkout guarantees, using the glossary's vocabulary
- [x] CHANGELOG has a 0.2.0 entry, including the note that an existing Repository aliased `pull` is now shadowed by the command and stays reachable by position and from the menu
- [x] The "Update the main branch" item is removed from the ROADMAP
- [x] pingo's version is 0.2.0
- [x] Full test suite passes under every shell in the test runner
