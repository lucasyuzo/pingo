# 04: `pingo pull .` for the current Repository

**What to build:** `pingo pull .` pulls the registered Repository that contains the current directory, so the flow `pingo api && pingo pull .` works (see spec: "New command `pull`").

**Blocked by:** 01

**Status:** done

- [x] Works from a Repository's root and from any subdirectory of it
- [x] With nested registered Repositories, the deepest match wins
- [x] Outside any registered Repository → clear error, exit `1`, nothing pulled
- [x] Behaves like single-Repository Pull for output and exit code
- [x] Tab completion for `pingo pull <TAB>` offers `.` along with aliases and names
- [x] `pingo help` mentions `.`
- [x] New messages exist in `en` and `pt-BR`
