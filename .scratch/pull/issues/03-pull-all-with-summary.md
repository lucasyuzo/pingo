# 03: Pull every Repository with a summary

**What to build:** `pingo pull` with no arguments pulls every registered Repository sequentially in list order, prints one progress line per Repository, then a summary block (see spec: "Output and exit codes", "Execution").

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Repositories are pulled in list order, one result line each
- [ ] Summary counts updated, already up to date, skipped, and failed, and lists the reason for each skip/failure
- [ ] A failure in one Repository doesn't stop the run
- [ ] Exit `1` iff at least one Repository failed; skips alone exit `0`
- [ ] Empty list shows the existing empty hint and exits `0`
- [ ] `pingo help` shows the no-argument form
- [ ] New messages exist in `en` and `pt-BR`
