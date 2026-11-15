# Path handling and git branch detection.
T_DIR=${T_DIR:-${0%/*}}
. "$T_DIR/lib.sh"
_pingo_init

# --- Windows path conversion (pure function, tested on every OS) ---
_pingo_winpath 'C:\Users\dev\api';      assert_eq "$_PINGO_WP" "/c/Users/dev/api" 'C:\ backslashes'
_pingo_winpath 'D:/work/web';           assert_eq "$_PINGO_WP" "/d/work/web" "D:/ forward slashes"
_pingo_winpath 'c:';                    assert_eq "$_PINGO_WP" "/c" "bare drive"
_pingo_winpath '/c/Users/dev';          assert_eq "$_PINGO_WP" "/c/Users/dev" "already POSIX"
_pingo_winpath 'relative\dir';          assert_eq "$_PINGO_WP" "relative/dir" "relative with backslash"

# --- normalization ---
mkdir -p "$T_TMP/p/q" "$HOME/proj"
_pingo_normpath "$T_TMP/p/q/";  assert_eq "$_PINGO_NP" "$T_TMP/p/q" "trailing slash removed"
_pingo_normpath "$T_TMP/p/./q/../q"; assert_eq "$_PINGO_NP" "$T_TMP/p/q" "dots resolved"
cd "$T_TMP/p" || exit 1
_pingo_normpath "q";  assert_eq "$_PINGO_NP" "$T_TMP/p/q" "relative path"
_pingo_normpath ".";  assert_eq "$_PINGO_NP" "$T_TMP/p" "dot"
_pingo_normpath "~/proj"; assert_eq "$_PINGO_NP" "$HOME/proj" "literal ~/ expanded"
CDPATH="$T_TMP" _pingo_normpath "p"; st=$?
assert_status $st 1 "CDPATH is ignored"
_pingo_normpath "$T_TMP/missing"; st=$?
assert_status $st 1 "missing directory"
cd "$T_TMP" || exit 1

# --- display helpers ---
_pingo_tilde "$HOME/proj";  assert_eq "$_PINGO_TL" "~/proj" "tilde"
_pingo_tilde "$HOME";       assert_eq "$_PINGO_TL" "~" "tilde home"
_pingo_tilde "/etc";        assert_eq "$_PINGO_TL" "/etc" "tilde outside home"
_pingo_basename "/a/b/c/";  assert_eq "$_PINGO_BN" "c" "basename trailing slash"
_pingo_basename "/";        assert_eq "$_PINGO_BN" "/" "basename root"
_pingo_lower "C:/Users/ABC"; assert_eq "$_PINGO_LOWS" "c:/users/abc" "lower"

# --- branch detection ---
t_repo "$T_TMP/g1" develop
_pingo_branch "$T_TMP/g1"; assert_eq "$_PINGO_BR" "develop" "branch from .git/HEAD"

mkdir -p "$T_TMP/g2/.git"
printf '0123456789abcdef0123456789abcdef01234567\n' >"$T_TMP/g2/.git/HEAD"
_pingo_branch "$T_TMP/g2"; assert_eq "$_PINGO_BR" "0123456" "detached HEAD shows short sha"

mkdir -p "$T_TMP/g3" "$T_TMP/g1/.git/worktrees/g3"
printf 'ref: refs/heads/feature/x\n' >"$T_TMP/g1/.git/worktrees/g3/HEAD"
printf 'gitdir: %s\n' "$T_TMP/g1/.git/worktrees/g3" >"$T_TMP/g3/.git"
_pingo_branch "$T_TMP/g3"; assert_eq "$_PINGO_BR" "feature/x" "worktree (.git file, absolute gitdir)"

mkdir -p "$T_TMP/g4" "$T_TMP/modules/g4"
printf 'ref: refs/heads/sub\r\n' >"$T_TMP/modules/g4/HEAD"
printf 'gitdir: ../modules/g4\n' >"$T_TMP/g4/.git"
_pingo_branch "$T_TMP/g4"; assert_eq "$_PINGO_BR" "sub" "submodule (.git file, relative gitdir, CRLF)"

mkdir -p "$T_TMP/plain"
_pingo_branch "$T_TMP/plain"; st=$?
assert_status $st 1 "not a git repository"

# --- a real git repository, if git is available ---
if command -v git >/dev/null 2>&1; then
  git init -q -b trunk "$T_TMP/real" 2>/dev/null || { git init -q "$T_TMP/real" && git -C "$T_TMP/real" symbolic-ref HEAD refs/heads/trunk; }
  _pingo_branch "$T_TMP/real"; assert_eq "$_PINGO_BR" "trunk" "real git repository"
fi

t_done
