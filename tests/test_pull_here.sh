# pingo pull . : Pull the registered Repository that contains the current directory.
T_DIR=${T_DIR:-${0%/*}}
. "$T_DIR/lib.sh"

# --- from the Repository's root ---
t_git_repo "$T_TMP/work/api"
pingo add "$T_TMP/work/api" >/dev/null 2>&1
t_git_advance "$T_TMP/work/api" 2
out=$(cd "$T_TMP/work/api" && pingo pull . 2>&1); st=$?
assert_status $st 0 "pull . from the root succeeds"
assert_contains "$out" "api: main updated, 2 commits" "pull . reports like single-Repository Pull"
assert_eq "$(t_git_rev "$T_TMP/work/api" main)" "$(t_git_rev "$T_TMP/work/api.seed" main)" "pull . from the root reaches the remote"

# --- from a subdirectory ---
mkdir -p "$T_TMP/work/api/src/deep"
t_git_advance "$T_TMP/work/api" 1
out=$(cd "$T_TMP/work/api/src/deep" && pingo pull . 2>&1); st=$?
assert_status $st 0 "pull . from a subdirectory succeeds"
assert_contains "$out" "api: main updated, 1 commit" "subdirectory resolves to the containing Repository"

# --- already up to date: same output and exit code as single-Repository Pull ---
out=$(cd "$T_TMP/work/api" && pingo pull . 2>&1); st=$?
assert_status $st 0 "pull . already up to date succeeds"
assert_eq "$out" "$(pingo pull api 2>&1)" "pull . output matches pull <name>"

# --- a sibling whose name shares a prefix is not a match ---
mkdir -p "$T_TMP/work/api-docs"
out=$(cd "$T_TMP/work/api-docs" && pingo pull . 2>&1); st=$?
assert_status $st 1 "prefix sibling is not inside the Repository"

# --- nested registered Repositories: the deepest match wins ---
t_git_repo "$T_TMP/work/mono"
t_git_repo "$T_TMP/work/mono/packages/lib"
pingo add "$T_TMP/work/mono/packages/lib" >/dev/null 2>&1
pingo add "$T_TMP/work/mono" >/dev/null 2>&1
t_git_advance "$T_TMP/work/mono" 1
t_git_advance "$T_TMP/work/mono/packages/lib" 2
outer=$(t_git_rev "$T_TMP/work/mono" main)
out=$(cd "$T_TMP/work/mono/packages/lib" && pingo pull . 2>&1); st=$?
assert_status $st 0 "nested: pull . succeeds"
assert_contains "$out" "lib: main updated, 2 commits" "nested: the deepest Repository is pulled"
assert_eq "$(t_git_rev "$T_TMP/work/mono" main)" "$outer" "nested: the outer Repository is untouched"
out=$(cd "$T_TMP/work/mono/packages" && pingo pull . 2>&1)
assert_contains "$out" "mono: main updated, 1 commit" "nested: outside the inner one, the outer Repository is pulled"

# --- through a symlink to a registered Repository ---
ln -s "$T_TMP/work/api" "$T_TMP/link-api"
t_git_advance "$T_TMP/work/api" 1
out=$(cd "$T_TMP/link-api/src" && pingo pull . 2>&1); st=$?
assert_status $st 0 "symlinked path: pull . succeeds"
assert_contains "$out" "api: main updated, 1 commit" "symlinked path resolves to the registered Repository"

# --- outside any registered Repository ---
mkdir -p "$T_TMP/elsewhere"
head=$(t_git_rev "$T_TMP/work/api" main)
t_git_advance "$T_TMP/work/api" 1
out=$(cd "$T_TMP/elsewhere" && pingo pull . 2>&1); st=$?
assert_status $st 1 "outside: exit 1"
assert_contains "$out" "is not inside a registered repository" "outside: clear error"
assert_eq "$(t_git_rev "$T_TMP/work/api" main)" "$head" "outside: nothing is pulled"
out=$(cd "$T_TMP/elsewhere" && LANG=pt_BR.UTF-8 pingo pull . 2>&1)
assert_contains "$out" "não está dentro de um repositório registrado" "outside: pt-BR error"

# --- completion and help ---
words="$_PINGO_NL$(_pingo_completion_pull)$_PINGO_NL"
assert_contains "$words" "${_PINGO_NL}.$_PINGO_NL" "pull completion offers ."
assert_contains "$words" "${_PINGO_NL}api$_PINGO_NL" "pull completion offers names"
if [ -n "${BASH_VERSION:-}" ]; then
  COMP_WORDS=(pingo pull "") COMP_CWORD=2
  _pingo_bash_complete
  assert_contains " ${COMPREPLY[*]} " " . " "bash: pingo pull <TAB> offers ."
  COMP_WORDS=(pingo rm "")
  _pingo_bash_complete
  assert_not_contains " ${COMPREPLY[*]} " " . " "bash: rm does not offer ."
fi
assert_contains "$(pingo help)" "pingo pull ." "help mentions pull ."
assert_contains "$(LANG=pt_BR.UTF-8 pingo help)" "faz o pull do repositório registrado em que você está" "pt-BR help mentions pull ."

t_done
