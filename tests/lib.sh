# shellcheck shell=bash
# Tiny test helpers, compatible with bash >= 3.2 and zsh >= 5.
# Each test file sources this, which sets up an isolated HOME/XDG dir
# and loads pingo.sh.

T_ROOT=$(CDPATH= cd -- "${T_DIR:-.}/.." && pwd)
T_TMP=$(mktemp -d 2>/dev/null || mktemp -d -t pingo)
T_TMP=$(CDPATH= cd -- "$T_TMP" && pwd -P)
export HOME="$T_TMP/home"
export XDG_CONFIG_HOME="$T_TMP/config"
export NO_COLOR=1 LANG=en_US.UTF-8 LC_ALL= LC_MESSAGES=
unset PINGO_DATA_DIR
mkdir -p "$HOME"
cd "$T_TMP" || exit 1

. "$T_ROOT/pingo.sh"

T_PASS=0
T_FAIL=0

t_pass() { T_PASS=$((T_PASS + 1)); }
t_fail() {
  T_FAIL=$((T_FAIL + 1))
  printf '  FAIL: %s\n' "$1"
  [ -n "${2:-}" ] && printf '%s\n' "$2"
  return 0
}

assert_eq() { # actual expected message
  if [ "$1" = "$2" ]; then t_pass; else t_fail "$3" "    expected: [$2]
    actual:   [$1]"; fi
}

assert_contains() { # haystack needle message
  case "$1" in
    *"$2"*) t_pass ;;
    *) t_fail "$3" "    expected to contain: [$2]
    in: [$1]" ;;
  esac
}

assert_not_contains() {
  case "$1" in
    *"$2"*) t_fail "$3" "    expected NOT to contain: [$2]
    in: [$1]" ;;
    *) t_pass ;;
  esac
}

assert_status() { # actual expected message
  if [ "$1" -eq "$2" ]; then t_pass; else t_fail "$3" "    expected status $2, got $1"; fi
}

# Make a fake git repository: t_repo <dir> [branch]
t_repo() {
  mkdir -p "$1/.git"
  printf 'ref: refs/heads/%s\n' "${2:-main}" >"$1/.git/HEAD"
}

# --- real git fixture (local only, no network) ---
# t_git_repo <dir> [branch]: a bare remote "<dir>.remote.git" whose Default
# branch has one commit, and a clone of it in <dir>. A separate clone,
# "<dir>.seed", is used by t_git_advance to push new commits to the remote.
export GIT_CONFIG_NOSYSTEM=1 GIT_AUTHOR_NAME=pingo GIT_AUTHOR_EMAIL=pingo@example.com
export GIT_COMMITTER_NAME=pingo GIT_COMMITTER_EMAIL=pingo@example.com

t_git() { # git quietly, with fixed settings
  git -c init.defaultBranch=main -c advice.detachedHead=false "$@" >/dev/null 2>&1
}

t_git_repo() {
  local dir=$1 br=${2:-main}
  t_git init -q --bare "$dir.remote.git"
  t_git --git-dir="$dir.remote.git" symbolic-ref HEAD "refs/heads/$br"
  t_git init -q "$dir.seed"
  t_git -C "$dir.seed" checkout -q -b "$br"
  printf '0\n' >"$dir.seed/file"
  t_git -C "$dir.seed" add file
  t_git -C "$dir.seed" commit -q -m c0
  t_git -C "$dir.seed" remote add origin "$dir.remote.git"
  t_git -C "$dir.seed" push -q -u origin "$br"
  t_git clone -q "$dir.remote.git" "$dir"
}

# t_git_advance <dir> <n>: push n new commits to the remote's Default branch.
t_git_advance() {
  local i=1
  while [ "$i" -le "$2" ]; do
    printf '%s\n' "$i" >>"$1.seed/file"
    t_git -C "$1.seed" commit -q -a -m "c$i"
    i=$((i + 1))
  done
  t_git -C "$1.seed" push -q
}

# t_git_rev <dir> <ref> [--short]: commit a ref points to.
t_git_rev() {
  if [ -n "${3:-}" ]; then
    git -C "$1" rev-parse --short "$2" 2>/dev/null
  else
    git -C "$1" rev-parse "$2" 2>/dev/null
  fi
}

t_reset() {
  rm -rf "$XDG_CONFIG_HOME"
  cd "$T_TMP" || exit 1
}

t_done() {
  cd / || true
  rm -rf "$T_TMP"
  printf '  %s passed, %s failed\n' "$T_PASS" "$T_FAIL"
  [ "$T_FAIL" -eq 0 ]
}
