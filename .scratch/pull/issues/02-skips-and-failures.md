# 02: Skips and failures

**What to build:** Pull never touches a Repository it can't update safely, and reports clearly when git refuses. Extends the Pull core from 01 with the spec's pre-check skip reasons and failure classification (see spec: "Pre-checks that skip", "Failures", "Result categories").

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Skipped, with a reason, and nothing touched: directory missing; not a git repository; no remote; no Default branch found; checkout is the Default branch with tracked uncommitted changes (staged or unstaged); checkout is the Default branch with a merge or rebase in progress; Default branch checked out in another worktree
- [ ] Untracked files on the Default branch do not cause a skip
- [ ] Failed, with a short reason: diverged (not a fast-forward); unreachable remote; authentication required (does not hang waiting for input)
- [ ] Single-Repository Pull exits `1` when skipped or failed
- [ ] Every skip/failure reason exists in `en` and `pt-BR`
- [ ] Tests assert the real git state is unchanged for every skip and failure
