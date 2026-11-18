# Pull every Repository: `pingo pull` with no arguments.
T_DIR=${T_DIR:-${0%/*}}
. "$T_DIR/lib.sh"

# --- empty list: the existing empty hint, exit 0 ---
out=$(pingo pull 2>&1); st=$?
assert_status $st 0 "empty list exits 0"
assert_contains "$out" "No repositories yet." "empty list shows the empty hint"

# --- every Repository in list order, a failure doesn't stop the run ---
t_git_repo "$T_TMP/work/api"
t_git_repo "$T_TMP/work/web"
t_git_repo "$T_TMP/work/docs"
pingo add "$T_TMP/work/api" >/dev/null 2>&1
pingo add "$T_TMP/work/web" >/dev/null 2>&1
pingo add "$T_TMP/work/docs" >/dev/null 2>&1
t_git_advance "$T_TMP/work/api" 2
t_git_advance "$T_TMP/work/docs" 1
# web's remote is gone: its Pull fails.
t_git -C "$T_TMP/work/web" remote set-url origin "$T_TMP/work/nowhere.git"
out=$(pingo pull 2>&1); st=$?
assert_status $st 1 "a failed Repository makes the run exit 1"
assert_eq "$(t_git_rev "$T_TMP/work/api" main)" "$(t_git_rev "$T_TMP/work/api.seed" main)" "api reaches the remote"
assert_eq "$(t_git_rev "$T_TMP/work/docs" main)" "$(t_git_rev "$T_TMP/work/docs.seed" main)" "docs is pulled after web failed"
lines=$(printf '%s\n' "$out" | grep -E '^. (api|web|docs):' | sed 's/^. \([a-z]*\):.*/\1/' | tr '\n' ' ')
assert_eq "$lines" "api web docs " "one result line per Repository, in list order"
assert_contains "$out" "api: main updated, 2 commits" "api result line"
assert_contains "$out" "web: pull failed" "web result line"
assert_contains "$out" "docs: main updated, 1 commit" "docs result line"
assert_contains "$out" "Summary: 2 updated, 0 already up to date, 0 skipped, 1 failed" "summary counts"
summary=${out#*Summary:}
assert_contains "$summary" "web" "summary lists the failed Repository"
assert_not_contains "$summary" "api" "summary doesn't list updated Repositories"

# --- all current: exit 0 ---
t_git -C "$T_TMP/work/web" remote set-url origin "$T_TMP/work/web.remote.git"
out=$(pingo pull 2>&1); st=$?
assert_status $st 0 "no failures exits 0"
assert_contains "$out" "Summary: 0 updated, 3 already up to date, 0 skipped, 0 failed" "all current summary"

# --- without git: fails immediately ---
mkdir -p "$T_TMP/nogit"
out=$(PATH="$T_TMP/nogit"; hash -r; pingo pull 2>&1); st=$?
assert_status $st 1 "without git: fails"
assert_contains "$out" "git was not found" "without git: same message as update"
assert_not_contains "$out" "Summary" "without git: no summary"

# --- extra arguments are a usage error ---
out=$(pingo pull api web 2>&1); st=$?
assert_status $st 2 "extra arguments exit 2"

# --- help shows the no-argument form ---
out=$(pingo help 2>&1)
assert_contains "$out" "pingo pull [" "help shows pull with an optional argument"

# --- pt-BR ---
pingo config lang pt-BR >/dev/null 2>&1
out=$(pingo pull 2>&1)
assert_contains "$out" "Resumo: 0 atualizados, 3 já em dia, 0 ignorados, 0 falharam" "pt-BR summary"
pingo config lang en >/dev/null 2>&1

t_done
