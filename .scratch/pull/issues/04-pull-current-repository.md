# 04: `pingo pull .` for the current Repository

**What to build:** `pingo pull .` pulls the registered Repository that contains the current directory, so the flow `pingo api && pingo pull .` works (see spec: "New command `pull`").

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Works from a Repository's root and from any subdirectory of it
- [ ] With nested registered Repositories, the deepest match wins
- [ ] Outside any registered Repository → clear error, exit `1`, nothing pulled
- [ ] Behaves like single-Repository Pull for output and exit code
- [ ] Tab completion for `pingo pull <TAB>` offers `.` along with aliases and names
- [ ] `pingo help` mentions `.`
- [ ] New messages exist in `en` and `pt-BR`
