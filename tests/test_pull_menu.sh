# Pull from the interactive menu: keys `p` (selected) and `P` (all).
T_DIR=${T_DIR:-${0%/*}}
. "$T_DIR/lib.sh"

KEYS="$T_TMP/keys"
DOWN=$(printf '\033[B')

menu() { # keys...
  printf '%s' "$@" >"$KEYS"
  pingo <"$KEYS" >"$T_TMP/out" 2>&1
}
out() { cat "$T_TMP/out"; }

t_git_repo "$T_TMP/work/api"
t_git_repo "$T_TMP/work/web"
pingo add "$T_TMP/work/api" >/dev/null 2>&1
pingo add "$T_TMP/work/web" >/dev/null 2>&1

# --- p: pulls the selected Repository, stays selected, Enter jumps to it ---
t_git_advance "$T_TMP/work/web" 2
menu "$DOWN" "p" "
"
assert_eq "$(t_git_rev "$T_TMP/work/web" main)" "$(t_git_rev "$T_TMP/work/web.seed" main)" "p pulls the selected Repository"
assert_contains "$(out)" "pulling web…" "p shows the pulling indicator"
assert_contains "$(out)" "web: main updated, 2 commits" "p shows the result in the message line"
assert_eq "$PWD" "$T_TMP/work/web" "after p the selection is kept and Enter jumps to it"
cd "$T_TMP" || exit 1

# --- p pulls only the selected Repository, not the others on screen ---
t_git_advance "$T_TMP/work/api" 1
t_git_advance "$T_TMP/work/web" 1
web_before=$(t_git_rev "$T_TMP/work/web" main)
menu "p" "q"
assert_eq "$(t_git_rev "$T_TMP/work/api" main)" "$(t_git_rev "$T_TMP/work/api.seed" main)" "p on the first entry pulls it"
assert_eq "$(t_git_rev "$T_TMP/work/web" main)" "$web_before" "p leaves the other Repositories alone"
assert_contains "$(out)" "api: main updated, 1 commit" "p reports the selected Repository"

# --- p on a failing Repository: failure in the message line, nothing jumps ---
t_git -C "$T_TMP/work/web" remote set-url origin "$T_TMP/work/nowhere.git"
menu "$DOWN" "p" "q"
assert_contains "$(out)" "web: pull failed" "p shows a failure in the message line"
assert_eq "$PWD" "$T_TMP" "p never changes directory"
t_git -C "$T_TMP/work/web" remote set-url origin "$T_TMP/work/web.remote.git"

# --- P: pulls every Repository with the CLI summary, waits for Enter, back to menu ---
t_git_advance "$T_TMP/work/api" 1
t_git_advance "$T_TMP/work/web" 1
menu "P" "
" "$DOWN" "
"
assert_eq "$(t_git_rev "$T_TMP/work/api" main)" "$(t_git_rev "$T_TMP/work/api.seed" main)" "P pulls api"
assert_eq "$(t_git_rev "$T_TMP/work/web" main)" "$(t_git_rev "$T_TMP/work/web.seed" main)" "P pulls web"
assert_contains "$(out)" "api: main updated, 1 commit" "P shows the progress lines"
assert_contains "$(out)" "Summary: 2 updated, 0 already up to date, 0 skipped, 0 failed" "P shows the summary"
assert_contains "$(out)" "Press Enter to go back to the menu." "P waits for Enter"
assert_eq "$PWD" "$T_TMP/work/web" "after P Enter returns to the menu"
cd "$T_TMP" || exit 1

# --- P: q and Esc also return to the menu (they don't quit it) ---
menu "P" "q" "$DOWN" "
"
assert_eq "$PWD" "$T_TMP/work/web" "after P, q returns to the menu"
cd "$T_TMP" || exit 1
menu "P" "$(printf '\033')" "x" "$DOWN" "
"
assert_eq "$PWD" "$T_TMP/work/web" "after P, Esc returns to the menu"
cd "$T_TMP" || exit 1

# --- without git: both keys report "git not found" instead of pulling ---
t_git_advance "$T_TMP/work/api" 1
before=$(t_git_rev "$T_TMP/work/api" main)
mkdir -p "$T_TMP/nogit"
printf '%s' "p" "P" "q" >"$KEYS"
nogit=$(PATH="$T_TMP/nogit"; hash -r; pingo <"$KEYS" 2>&1)
hash -r
assert_eq "$(t_git_rev "$T_TMP/work/api" main)" "$before" "without git: nothing is pulled"
assert_contains "$nogit" "git was not found" "without git: the message line says so"
assert_not_contains "$nogit" "Summary" "without git: P doesn't run the pull"
assert_not_contains "$nogit" "Press Enter" "without git: P stays in the menu"

# --- discoverable: menu footer, help screen and `pingo help` ---
menu "q"
assert_contains "$(out)" "p pull" "footer shows p"
assert_contains "$(out)" "P pull all" "footer shows P"
menu "?" "x" "q"
assert_contains "$(out)" "pull the selected repository" "menu help lists p"
assert_contains "$(out)" "pull every repository" "menu help lists P"
help=$(pingo help 2>&1)
assert_contains "$help" "pull the selected repository" "pingo help lists p"
assert_contains "$help" "pull every repository" "pingo help lists P"

# --- pt-BR ---
pingo config lang pt-BR >/dev/null 2>&1
menu "p" "q"
assert_contains "$(out)" "fazendo o pull de api…" "pt-BR pulling indicator"
assert_contains "$(out)" "api: main atualizada, 1 commit" "pt-BR result in the message line"
menu "P" "
" "q"
assert_contains "$(out)" "Pressione Enter para voltar ao menu." "pt-BR P waits for Enter"
assert_contains "$(out)" "p pull" "pt-BR footer shows p"
menu "?" "x" "q"
assert_contains "$(out)" "fazer o pull do repositório selecionado" "pt-BR menu help lists p"
pingo config lang en >/dev/null 2>&1

t_done
