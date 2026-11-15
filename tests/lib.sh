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
