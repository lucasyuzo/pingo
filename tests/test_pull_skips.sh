# Pull: Repositories that can't be pulled safely are skipped; git refusals fail.
T_DIR=${T_DIR:-${0%/*}}
. "$T_DIR/lib.sh"

# t_snap <dir>: the git state Pull must never change on a skip or failure
# (every local ref, HEAD, index and working tree).
t_snap() {
  git -C "$1" for-each-ref --format='%(refname) %(objectname)' 2>/dev/null
  git -C "$1" rev-parse HEAD 2>/dev/null
  git -C "$1" symbolic-ref -q HEAD 2>/dev/null
  git -C "$1" status --porcelain 2>/dev/null
  git -C "$1" diff 2>/dev/null
  git -C "$1" diff --cached 2>/dev/null
}

# --- directory missing ---
mkdir -p "$T_TMP/work/gone"
pingo add "$T_TMP/work/gone" >/dev/null 2>&1
rmdir "$T_TMP/work/gone"
out=$(pingo pull gone 2>&1); st=$?
assert_status $st 1 "missing directory: exit 1"
assert_contains "$out" "gone: skipped (directory not found)" "missing directory: skipped with reason"
[ -e "$T_TMP/work/gone" ]; assert_status $? 1 "missing directory: nothing created"

# --- not a git repository (even when nested inside one) ---
mkdir -p "$T_TMP/work/plain"
printf 'x\n' >"$T_TMP/work/plain/file"
pingo add "$T_TMP/work/plain" >/dev/null 2>&1
out=$(pingo pull plain 2>&1); st=$?
assert_status $st 1 "not git: exit 1"
assert_contains "$out" "plain: skipped (not a git repository)" "not git: skipped with reason"
[ -e "$T_TMP/work/plain/.git" ]; assert_status $? 1 "not git: nothing created"

t_git_repo "$T_TMP/work/outer"
mkdir -p "$T_TMP/work/outer/inner"
pingo add "$T_TMP/work/outer/inner" >/dev/null 2>&1
t_git_advance "$T_TMP/work/outer" 1
before=$(t_snap "$T_TMP/work/outer")
out=$(pingo pull inner 2>&1); st=$?
assert_status $st 1 "nested plain directory: exit 1"
assert_contains "$out" "inner: skipped (not a git repository)" "nested plain directory: skipped"
assert_eq "$(t_snap "$T_TMP/work/outer")" "$before" "nested plain directory: enclosing repository untouched"

# --- no remote: no upstream and no origin ---
t_git_repo "$T_TMP/work/lonely"
t_git -C "$T_TMP/work/lonely" remote remove origin
pingo add "$T_TMP/work/lonely" >/dev/null 2>&1
before=$(t_snap "$T_TMP/work/lonely")
out=$(pingo pull lonely 2>&1); st=$?
assert_status $st 1 "no remote: exit 1"
assert_contains "$out" "lonely: skipped (no remote)" "no remote: skipped with reason"
assert_eq "$(t_snap "$T_TMP/work/lonely")" "$before" "no remote: git state unchanged"

# An upstream pointing at a remote that no longer exists counts as no remote.
t_git_repo "$T_TMP/work/stale"
t_git -C "$T_TMP/work/stale" remote rename origin upstream
t_git -C "$T_TMP/work/stale" config branch.main.remote gone
pingo add "$T_TMP/work/stale" >/dev/null 2>&1
before=$(t_snap "$T_TMP/work/stale")
out=$(pingo pull stale 2>&1); st=$?
assert_status $st 1 "stale upstream, no origin: exit 1"
assert_contains "$out" "stale: skipped (no remote)" "stale upstream, no origin: skipped"
assert_eq "$(t_snap "$T_TMP/work/stale")" "$before" "stale upstream: git state unchanged"

# --- no Default branch: no declared remote HEAD, no main, no master ---
t_git_repo "$T_TMP/work/dev" dev
t_git -C "$T_TMP/work/dev" remote set-head origin -d
pingo add "$T_TMP/work/dev" >/dev/null 2>&1
t_git_advance "$T_TMP/work/dev" 1
before=$(t_snap "$T_TMP/work/dev")
out=$(pingo pull dev 2>&1); st=$?
assert_status $st 1 "no Default branch: exit 1"
assert_contains "$out" "dev: skipped (no default branch found)" "no Default branch: skipped with reason"
assert_eq "$(t_snap "$T_TMP/work/dev")" "$before" "no Default branch: git state unchanged"

# --- checkout is the Default branch with tracked uncommitted changes ---
t_git_repo "$T_TMP/work/dirty"
pingo add "$T_TMP/work/dirty" >/dev/null 2>&1
t_git_advance "$T_TMP/work/dirty" 1
printf 'wip\n' >>"$T_TMP/work/dirty/file"
before=$(t_snap "$T_TMP/work/dirty")
out=$(pingo pull dirty 2>&1); st=$?
assert_status $st 1 "unstaged changes: exit 1"
assert_contains "$out" "dirty: skipped (uncommitted changes)" "unstaged changes: skipped with reason"
assert_eq "$(t_snap "$T_TMP/work/dirty")" "$before" "unstaged changes: git state unchanged"

t_git_repo "$T_TMP/work/staged"
pingo add "$T_TMP/work/staged" >/dev/null 2>&1
t_git_advance "$T_TMP/work/staged" 1
printf 'new\n' >"$T_TMP/work/staged/other"
t_git -C "$T_TMP/work/staged" add other
before=$(t_snap "$T_TMP/work/staged")
out=$(pingo pull staged 2>&1); st=$?
assert_status $st 1 "staged changes: exit 1"
assert_contains "$out" "staged: skipped (uncommitted changes)" "staged changes: skipped with reason"
assert_eq "$(t_snap "$T_TMP/work/staged")" "$before" "staged changes: git state unchanged"

# --- untracked files on the Default branch do not skip ---
t_git_repo "$T_TMP/work/stray"
pingo add "$T_TMP/work/stray" >/dev/null 2>&1
t_git_advance "$T_TMP/work/stray" 1
printf 'scratch\n' >"$T_TMP/work/stray/notes.txt"
out=$(pingo pull stray 2>&1); st=$?
assert_status $st 0 "untracked files: pull succeeds"
assert_contains "$out" "stray: main updated" "untracked files: updated"
assert_eq "$(t_git_rev "$T_TMP/work/stray" main)" "$(t_git_rev "$T_TMP/work/stray.seed" main)" "untracked files: default branch advances"
assert_eq "$(cat "$T_TMP/work/stray/notes.txt")" "scratch" "untracked files: left alone"

# --- checkout is the Default branch with a merge in progress ---
t_git_repo "$T_TMP/work/merging"
pingo add "$T_TMP/work/merging" >/dev/null 2>&1
t_git -C "$T_TMP/work/merging" checkout -q -b side
printf 'side\n' >"$T_TMP/work/merging/file"
t_git -C "$T_TMP/work/merging" commit -q -a -m side
t_git -C "$T_TMP/work/merging" checkout -q main
t_git -C "$T_TMP/work/merging" merge --no-ff --no-commit side
t_git_advance "$T_TMP/work/merging" 1
before=$(t_snap "$T_TMP/work/merging")
out=$(pingo pull merging 2>&1); st=$?
assert_status $st 1 "merge in progress: exit 1"
assert_contains "$out" "merging: skipped (merge in progress)" "merge in progress: skipped with reason"
assert_eq "$(t_snap "$T_TMP/work/merging")" "$before" "merge in progress: git state unchanged"
git -C "$T_TMP/work/merging" rev-parse -q --verify MERGE_HEAD >/dev/null; st=$?
assert_status $st 0 "merge in progress: still in progress"

# --- the Default branch with a rebase in progress (HEAD is detached meanwhile) ---
t_git_repo "$T_TMP/work/rebasing"
pingo add "$T_TMP/work/rebasing" >/dev/null 2>&1
t_git -C "$T_TMP/work/rebasing" rebase -x false --root
[ -d "$T_TMP/work/rebasing/.git/rebase-merge" ]; assert_status $? 0 "fixture: rebase stopped midway"
t_git_advance "$T_TMP/work/rebasing" 1
before=$(t_snap "$T_TMP/work/rebasing")
out=$(pingo pull rebasing 2>&1); st=$?
assert_status $st 1 "rebase in progress: exit 1"
assert_contains "$out" "rebasing: skipped (rebase in progress)" "rebase in progress: skipped with reason"
assert_eq "$(t_snap "$T_TMP/work/rebasing")" "$before" "rebase in progress: git state unchanged"

# A rebase of another branch does not block the Default branch.
t_git_repo "$T_TMP/work/rebfeat"
pingo add "$T_TMP/work/rebfeat" >/dev/null 2>&1
t_git -C "$T_TMP/work/rebfeat" checkout -q -b feat
t_git -C "$T_TMP/work/rebfeat" rebase -x false --root
t_git_advance "$T_TMP/work/rebfeat" 1
out=$(pingo pull rebfeat 2>&1); st=$?
assert_status $st 0 "rebase of a feature branch: pull succeeds"
assert_eq "$(t_git_rev "$T_TMP/work/rebfeat" main)" "$(t_git_rev "$T_TMP/work/rebfeat.seed" main)" "rebase of a feature branch: default branch advances"
[ -d "$T_TMP/work/rebfeat/.git/rebase-merge" ]; assert_status $? 0 "rebase of a feature branch: still in progress"

# --- Default branch checked out in another worktree ---
t_git_repo "$T_TMP/work/tree"
t_git -C "$T_TMP/work/tree" checkout -q -b feat
t_git -C "$T_TMP/work/tree" worktree add -q "$T_TMP/work/tree-main" main
pingo add "$T_TMP/work/tree" >/dev/null 2>&1
t_git_advance "$T_TMP/work/tree" 1
before=$(t_snap "$T_TMP/work/tree")
before_wt=$(t_snap "$T_TMP/work/tree-main")
out=$(pingo pull tree 2>&1); st=$?
assert_status $st 1 "default branch in another worktree: exit 1"
assert_contains "$out" "tree: skipped (default branch checked out in another worktree)" "default branch in another worktree: skipped with reason"
assert_eq "$(t_snap "$T_TMP/work/tree")" "$before" "default branch in another worktree: git state unchanged"
assert_eq "$(t_snap "$T_TMP/work/tree-main")" "$before_wt" "default branch in another worktree: that worktree unchanged"

# The linked worktree itself, on a feature branch, sees main in the main worktree.
t_git_repo "$T_TMP/work/wtmain"
t_git -C "$T_TMP/work/wtmain" worktree add -q -b feat "$T_TMP/work/wtfeat"
pingo add "$T_TMP/work/wtfeat" >/dev/null 2>&1
t_git_advance "$T_TMP/work/wtmain" 1
before=$(t_snap "$T_TMP/work/wtmain")
out=$(pingo pull wtfeat 2>&1); st=$?
assert_status $st 1 "linked worktree, main elsewhere: exit 1"
assert_contains "$out" "wtfeat: skipped (default branch checked out in another worktree)" "linked worktree, main elsewhere: skipped"
assert_eq "$(t_snap "$T_TMP/work/wtmain")" "$before" "linked worktree, main elsewhere: git state unchanged"

# --- failures: git refused, local state unchanged ---
# t_local <dir>: local branches, HEAD, index and working tree (a failed fetch may
# still have refreshed remote-tracking refs, which is harmless).
t_local() {
  git -C "$1" for-each-ref --format='%(refname) %(objectname)' refs/heads 2>/dev/null
  git -C "$1" rev-parse HEAD 2>/dev/null
  git -C "$1" symbolic-ref -q HEAD 2>/dev/null
  git -C "$1" status --porcelain 2>/dev/null
  git -C "$1" diff 2>/dev/null
  git -C "$1" diff --cached 2>/dev/null
}

# diverged, checkout is the Default branch
t_git_repo "$T_TMP/work/div"
pingo add "$T_TMP/work/div" >/dev/null 2>&1
printf 'mine\n' >"$T_TMP/work/div/mine"
t_git -C "$T_TMP/work/div" add mine
t_git -C "$T_TMP/work/div" commit -q -m mine
t_git_advance "$T_TMP/work/div" 1
before=$(t_local "$T_TMP/work/div")
out=$(pingo pull div 2>&1); st=$?
assert_status $st 1 "diverged: exit 1"
assert_contains "$out" "div: pull failed (diverged)" "diverged: failed with reason"
assert_eq "$(t_local "$T_TMP/work/div")" "$before" "diverged: local state unchanged"
assert_not_contains "$(git -C "$T_TMP/work/div" log --format=%s)" "Merge" "diverged: no merge commit"

# diverged, checkout is a feature branch
t_git -C "$T_TMP/work/div" checkout -q -b feat
before=$(t_local "$T_TMP/work/div")
out=$(pingo pull div 2>&1); st=$?
assert_status $st 1 "diverged from a feature branch: exit 1"
assert_contains "$out" "div: pull failed (diverged)" "diverged from a feature branch: failed with reason"
assert_eq "$(t_local "$T_TMP/work/div")" "$before" "diverged from a feature branch: local state unchanged"

# unreachable remote: a path that is gone, and a closed local port
t_git_repo "$T_TMP/work/far"
pingo add "$T_TMP/work/far" >/dev/null 2>&1
t_git -C "$T_TMP/work/far" remote set-url origin "$T_TMP/vanished.git"
before=$(t_snap "$T_TMP/work/far")
out=$(pingo pull far 2>&1); st=$?
assert_status $st 1 "unreachable remote: exit 1"
assert_contains "$out" "far: pull failed (remote unreachable)" "unreachable remote: failed with reason"
assert_eq "$(t_snap "$T_TMP/work/far")" "$before" "unreachable remote: git state unchanged"

t_git -C "$T_TMP/work/far" checkout -q -b feat
t_git -C "$T_TMP/work/far" remote set-url origin "http://127.0.0.1:9/repo.git"
before=$(t_snap "$T_TMP/work/far")
out=$(pingo pull far 2>&1); st=$?
assert_status $st 1 "refused connection: exit 1"
assert_contains "$out" "far: pull failed (remote unreachable)" "refused connection: failed with reason"
assert_eq "$(t_snap "$T_TMP/work/far")" "$before" "refused connection: git state unchanged"

# authentication required: a remote whose transport asks git for credentials.
# Prompts must be disabled: neither the terminal nor an askpass program (IDEs
# such as VS Code set GIT_ASKPASS) may be asked, or a pull-all run would stall.
mkdir -p "$T_TMP/bin"
cat >"$T_TMP/bin/git-remote-needauth" <<'SH'
#!/bin/sh
printf 'protocol=https\nhost=example.com\n\n' | git credential fill >/dev/null || exit 128
exit 0
SH
cat >"$T_TMP/bin/askpass" <<SH
#!/bin/sh
: >"$T_TMP/asked"
echo secret
SH
chmod +x "$T_TMP/bin/git-remote-needauth" "$T_TMP/bin/askpass"
export GIT_ASKPASS="$T_TMP/bin/askpass" SSH_ASKPASS="$T_TMP/bin/askpass"
t_git_repo "$T_TMP/work/locked"
pingo add "$T_TMP/work/locked" >/dev/null 2>&1
t_git -C "$T_TMP/work/locked" remote set-url origin "needauth::example.com/repo.git"
before=$(t_snap "$T_TMP/work/locked")
out=$(PATH="$T_TMP/bin:$PATH"; pingo pull locked 2>&1 </dev/null); st=$?
assert_status $st 1 "authentication required: exit 1"
assert_contains "$out" "locked: pull failed (authentication required)" "authentication required: failed with reason"
assert_eq "$(t_snap "$T_TMP/work/locked")" "$before" "authentication required: git state unchanged"

t_git -C "$T_TMP/work/locked" checkout -q -b feat
out=$(PATH="$T_TMP/bin:$PATH"; pingo pull locked 2>&1 </dev/null); st=$?
assert_status $st 1 "authentication required from a feature branch: exit 1"
assert_contains "$out" "locked: pull failed (authentication required)" "authentication required from a feature branch: failed with reason"
[ -e "$T_TMP/asked" ]; assert_status $? 1 "authentication required: askpass never invoked"
unset GIT_ASKPASS SSH_ASKPASS

# --- pt-BR ---
out=$(LANG=pt_BR.UTF-8 pingo pull dirty 2>&1)
assert_contains "$out" "dirty: ignorado (mudanças não commitadas)" "pt-BR: skipped with reason"
out=$(LANG=pt_BR.UTF-8 pingo pull div 2>&1)
assert_contains "$out" "div: o pull falhou (divergiu)" "pt-BR: failed with reason"

t_done
