# Pull: bring a Repository's Default branch up to date with its remote.
T_DIR=${T_DIR:-${0%/*}}
. "$T_DIR/lib.sh"

# --- checkout is the Default branch: fast-forwarded in place ---
t_git_repo "$T_TMP/work/api"
pingo add "$T_TMP/work/api" >/dev/null 2>&1
old=$(t_git_rev "$T_TMP/work/api" main --short)
t_git_advance "$T_TMP/work/api" 3
new=$(t_git_rev "$T_TMP/work/api.seed" main --short)
out=$(pingo pull api 2>&1); st=$?
assert_status $st 0 "pull by name succeeds"
assert_eq "$(t_git_rev "$T_TMP/work/api" main)" "$(t_git_rev "$T_TMP/work/api.seed" main)" "default branch reaches the remote"
assert_eq "$(tail -n 1 "$T_TMP/work/api/file")" "3" "working tree reflects the new commits"
assert_contains "$out" "updated" "result says updated"
assert_contains "$out" "3 commits" "result shows the commit count"
assert_contains "$out" "$old → $new" "result shows old → new short hashes"

# --- already up to date ---
out=$(pingo pull api 2>&1); st=$?
assert_status $st 0 "already up to date succeeds"
assert_contains "$out" "already up to date" "result says already up to date"
assert_not_contains "$out" "updated" "nothing to update is not reported as updated"

# --- by position, one commit ---
t_git_advance "$T_TMP/work/api" 1
out=$(pingo pull 1 2>&1); st=$?
assert_status $st 0 "pull by position succeeds"
assert_contains "$out" "1 commit (" "single commit result"
assert_eq "$(t_git_rev "$T_TMP/work/api" main)" "$(t_git_rev "$T_TMP/work/api.seed" main)" "pull by position reaches the remote"

# --- checkout is a feature branch with uncommitted changes ---
t_git_repo "$T_TMP/work/web"
pingo add "$T_TMP/work/web" front >/dev/null 2>&1
t_git -C "$T_TMP/work/web" checkout -q -b feat/login
printf 'wip\n' >>"$T_TMP/work/web/file"
printf 'new\n' >"$T_TMP/work/web/staged"
t_git -C "$T_TMP/work/web" add staged
feat=$(t_git_rev "$T_TMP/work/web" feat/login)
t_git_advance "$T_TMP/work/web" 2
out=$(pingo pull front 2>&1); st=$?
assert_status $st 0 "pull on a feature branch succeeds"
assert_contains "$out" "2 commits" "feature branch: commit count"
assert_eq "$(t_git_rev "$T_TMP/work/web" main)" "$(t_git_rev "$T_TMP/work/web.seed" main)" "feature branch: default branch advances"
assert_eq "$(git -C "$T_TMP/work/web" symbolic-ref --short HEAD)" "feat/login" "feature branch stays checked out"
assert_eq "$(t_git_rev "$T_TMP/work/web" feat/login)" "$feat" "feature branch is untouched"
assert_eq "$(tail -n 1 "$T_TMP/work/web/file")" "wip" "uncommitted changes are untouched"
assert_eq "$(git -C "$T_TMP/work/web" diff --cached --name-only)" "staged" "staged changes are untouched"

# --- detached HEAD ---
t_git_repo "$T_TMP/work/det"
pingo add "$T_TMP/work/det" >/dev/null 2>&1
t_git -C "$T_TMP/work/det" checkout -q --detach
head=$(t_git_rev "$T_TMP/work/det" HEAD)
t_git_advance "$T_TMP/work/det" 2
out=$(pingo pull det 2>&1); st=$?
assert_status $st 0 "pull with detached HEAD succeeds"
assert_eq "$(t_git_rev "$T_TMP/work/det" main)" "$(t_git_rev "$T_TMP/work/det.seed" main)" "detached: default branch advances"
assert_eq "$(t_git_rev "$T_TMP/work/det" HEAD)" "$head" "detached: HEAD unchanged"
git -C "$T_TMP/work/det" symbolic-ref -q HEAD >/dev/null 2>&1; st=$?
assert_status $st 1 "detached: HEAD stays detached"

# --- Default branch discovery ---
# The remote declares "trunk" while a local main also exists.
t_git_repo "$T_TMP/work/trunk" trunk
t_git -C "$T_TMP/work/trunk" branch main
pingo add "$T_TMP/work/trunk" >/dev/null 2>&1
t_git_advance "$T_TMP/work/trunk" 1
out=$(pingo pull trunk 2>&1)
assert_contains "$out" "trunk updated" "the remote's declared HEAD wins"
assert_eq "$(t_git_rev "$T_TMP/work/trunk" trunk)" "$(t_git_rev "$T_TMP/work/trunk.seed" trunk)" "declared HEAD branch advances"

# No declared HEAD: local main, else local master.
t_git_repo "$T_TMP/work/old" master
t_git -C "$T_TMP/work/old" remote set-head origin -d
pingo add "$T_TMP/work/old" >/dev/null 2>&1
t_git_advance "$T_TMP/work/old" 1
out=$(pingo pull old 2>&1); st=$?
assert_status $st 0 "pull with local master succeeds"
assert_contains "$out" "master updated" "falls back to local master"
assert_eq "$(t_git_rev "$T_TMP/work/old" master)" "$(t_git_rev "$T_TMP/work/old.seed" master)" "master advances"

t_git_repo "$T_TMP/work/both"
t_git -C "$T_TMP/work/both" remote set-head origin -d
t_git -C "$T_TMP/work/both" branch master
pingo add "$T_TMP/work/both" >/dev/null 2>&1
t_git_advance "$T_TMP/work/both" 1
out=$(pingo pull both 2>&1)
assert_contains "$out" "main updated" "local main wins over local master"

# --- remote: the Default branch's upstream, else origin ---
t_git_repo "$T_TMP/work/fork"
t_git -C "$T_TMP/work/fork" remote rename origin upstream
t_git -C "$T_TMP/work/fork" remote add origin "$T_TMP/nowhere.git"
pingo add "$T_TMP/work/fork" >/dev/null 2>&1
t_git_advance "$T_TMP/work/fork" 1
out=$(pingo pull fork 2>&1); st=$?
assert_status $st 0 "pull from the upstream remote succeeds"
assert_eq "$(t_git_rev "$T_TMP/work/fork" main)" "$(t_git_rev "$T_TMP/work/fork.seed" main)" "upstream remote is used"

t_git_repo "$T_TMP/work/noup"
t_git -C "$T_TMP/work/noup" checkout -q -b feat
t_git -C "$T_TMP/work/noup" branch --unset-upstream main
pingo add "$T_TMP/work/noup" >/dev/null 2>&1
t_git_advance "$T_TMP/work/noup" 1
out=$(pingo pull noup 2>&1); st=$?
assert_status $st 0 "pull without upstream succeeds"
assert_eq "$(t_git_rev "$T_TMP/work/noup" main)" "$(t_git_rev "$T_TMP/work/noup.seed" main)" "falls back to origin"

# --- only the Default branch is fetched ---
t_git -C "$T_TMP/work/api.seed" push -q origin main:other
t_git_advance "$T_TMP/work/api" 1
pingo pull api >/dev/null 2>&1
git -C "$T_TMP/work/api" show-ref -q --verify refs/remotes/origin/other; st=$?
assert_status $st 1 "other branches are not fetched"

# --- the shell's directory does not change ---
cd "$T_TMP/home" || exit 1
t_git_advance "$T_TMP/work/api" 1
pingo pull api >/dev/null 2>&1
assert_eq "$PWD" "$T_TMP/home" "pull does not change the current directory"
cd "$T_TMP" || exit 1

# --- errors ---
out=$(pingo pull nope 2>&1); st=$?
assert_status $st 1 "unknown alias fails"
assert_contains "$out" 'No repository named "nope"' "unknown alias: resolution error"
out=$(pingo pull 99 2>&1); st=$?
assert_status $st 1 "unknown position fails"
out=$(pingo pull api web 2>&1); st=$?
assert_status $st 2 "extra arguments: usage error"
assert_contains "$out" "Usage: pingo pull" "extra arguments: usage message"

mkdir -p "$T_TMP/nogit"
out=$(PATH="$T_TMP/nogit"; hash -r; pingo pull api 2>&1); st=$?
assert_status $st 1 "without git: fails"
assert_contains "$out" "git was not found" "without git: same message as update"
out=$(PATH="$T_TMP/nogit"; hash -r; pingo update 2>&1)
assert_contains "$out" "git was not found" "update shares the message"

# --- pull is a command word ---
assert_contains "$_PINGO_NL$(_pingo_completion_words)$_PINGO_NL" "${_PINGO_NL}pull$_PINGO_NL" "completion offers pull"
out=$(pingo add "$T_TMP/work" pull 2>&1); st=$?
assert_status $st 1 "pull is rejected as an alias"
assert_contains "$(pingo help)" "pingo pull [n|alias]" "help lists pull"

# --- pt-BR ---
t_git_advance "$T_TMP/work/api" 2
out=$(LANG=pt_BR.UTF-8 pingo pull api 2>&1)
assert_contains "$out" "main atualizada, 2 commits" "pt-BR: updated"
out=$(LANG=pt_BR.UTF-8 pingo pull api 2>&1)
assert_contains "$out" "main já está em dia" "pt-BR: already up to date"

t_done
