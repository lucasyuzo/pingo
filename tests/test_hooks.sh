# Git hooks in .githooks/: commit message format and no direct commits on main.
T_DIR=${T_DIR:-${0%/*}}
. "$T_DIR/lib.sh"

HOOKS="$T_ROOT/.githooks"

# --- commit-msg ---
msg() { # message -> exit status of the commit-msg hook
  printf '%s\n\nbody\n' "$1" >"$T_TMP/msg"
  sh "$HOOKS/commit-msg" "$T_TMP/msg" >/dev/null 2>&1
}
for ok in \
  "feat: pingo pull traz a Default branch em dia" \
  "fix(menu): q e Esc voltam ao menu" \
  "refactor: extrai helper" "test: cobre o pull" "docs: atualiza README" "chore: versão 0.2.0" \
  "Merge feat/pull: pingo pull (v0.2.0)" "Merge branch 'feat/pull' into ticket/02" \
  'Revert "feat: algo"' "fixup! feat: algo" "squash! fix: algo"; do
  msg "$ok"; assert_status $? 0 "commit-msg accepts [$ok]"
done
for bad in "adiciona pull" "feat:sem espaço" "feature: tipo inválido" "Feat: maiúscula" "feat(): escopo vazio" ""; do
  msg "$bad"; assert_status $? 1 "commit-msg rejects [$bad]"
done
printf '# comentário\nfeat: depois do comentário\n' >"$T_TMP/msg"
sh "$HOOKS/commit-msg" "$T_TMP/msg" >/dev/null 2>&1
assert_status $? 0 "commit-msg skips comment lines"
printf 'nope\n' >"$T_TMP/msg"
out=$(sh "$HOOKS/commit-msg" "$T_TMP/msg" 2>&1)
assert_contains "$out" "docs/agents/workflow.md" "commit-msg points to the workflow doc"

# --- pre-commit ---
repo="$T_TMP/hookrepo"
mkdir -p "$repo"
git -C "$repo" init -q -b main
git -C "$repo" config user.name t
git -C "$repo" config user.email t@t
git -C "$repo" config core.hooksPath "$HOOKS"
git -C "$repo" config commit.gpgsign false
printf 'a\n' >"$repo/a"
git -C "$repo" add a
git -C "$repo" commit -q --no-verify -m "chore: inicial"

printf 'b\n' >>"$repo/a"
git -C "$repo" commit -qam "fix: direto na main" >/dev/null 2>&1
assert_status $? 1 "pre-commit blocks a direct commit on main"

git -C "$repo" switch -q -c fix/x
git -C "$repo" commit -qam "fix: numa branch" >/dev/null 2>&1
assert_status $? 0 "pre-commit allows commits on other branches"

git -C "$repo" switch -q main
git -C "$repo" merge -q --no-ff -m "Merge fix/x: teste" fix/x >/dev/null 2>&1
assert_status $? 0 "merges into main are allowed"

# A conflicted merge finished with `git commit` is still a merge.
git -C "$repo" switch -q -c fix/y
printf 'y\n' >"$repo/a"; git -C "$repo" commit -qam "fix: lado y" >/dev/null 2>&1
git -C "$repo" switch -q main
git -C "$repo" switch -q -c fix/z
printf 'z\n' >"$repo/a"; git -C "$repo" commit -qam "fix: lado z" >/dev/null 2>&1
git -C "$repo" switch -q main
git -C "$repo" merge -q --no-ff -m "Merge fix/y: y" fix/y >/dev/null 2>&1
git -C "$repo" merge -q --no-ff fix/z >/dev/null 2>&1
printf 'yz\n' >"$repo/a"; git -C "$repo" add a
git -C "$repo" commit -q -m "Merge fix/z: resolve conflito" >/dev/null 2>&1
assert_status $? 0 "finishing a conflicted merge on main is allowed"

t_done
