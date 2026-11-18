# 05: Menu keys `p` and `P`

**What to build:** Pull from the interactive menu (see spec: "Menu"). `p` pulls the selected Repository without leaving the TUI; `P` pulls every Repository with the CLI's progress and summary, then returns to the menu.

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] `p` shows a "pulling <name>…" indicator in the message line, then the result (updated / already up to date / skipped or failed with reason)
- [ ] After `p`, the same Repository stays selected and Enter jumps to it
- [ ] `P` leaves the alternate screen, prints the same progress and summary as `pingo pull`, waits for Enter, then returns to the menu
- [ ] No confirmation prompt for either key
- [ ] Without `git`, both keys report the "git not found" message instead of pulling
- [ ] Both keys appear in the menu footer and in the help screen key list (menu and `pingo help`)
- [ ] New messages exist in `en` and `pt-BR`
- [ ] Menu tests drive `p` and `P` through the key file
