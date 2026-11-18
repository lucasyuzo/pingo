# shellcheck shell=bash
# ---------------------------------------------------------------------------
#  pingo — your faithful companion to jump between local repositories.
#  https://github.com/lucasyuzo/pingo  ·  MIT License
#
#  This file must be SOURCED, not executed:
#      . "$HOME/.pingo/pingo.sh"
#  It defines the `pingo` shell function. A function is the only way a tool
#  can change the directory of the shell you are typing in.
#
#  Works in zsh >= 5 and bash >= 3.2 (macOS, Linux and Git Bash on Windows),
#  using only shell builtins. Arrays are avoided on purpose (bash indexes
#  from 0, zsh from 1); lists are kept as newline-separated strings.
# ---------------------------------------------------------------------------

PINGO_VERSION="0.1.0"

# --- installation directory -------------------------------------------------
if [ -n "${ZSH_VERSION:-}" ]; then
  eval '_pingo_src=${(%):-%x}'
else
  _pingo_src=${BASH_SOURCE[0]:-$0}
fi
case "$_pingo_src" in
  */*) PINGO_HOME=${_pingo_src%/*} ;;
  *) PINGO_HOME=. ;;
esac
PINGO_HOME=$(
  CDPATH=
  if [ -n "${ZSH_VERSION:-}" ]; then builtin cd -q -- "$PINGO_HOME"; else builtin cd -- "$PINGO_HOME"; fi && pwd
)
unset _pingo_src

_PINGO_NL='
'
_PINGO_RESERVED=" ls list add rm remove mv move rename prune config update pull help version "

# --- small helpers ----------------------------------------------------------

_pingo_is_windows() {
  case "${OSTYPE:-}" in msys* | cygwin* | win32*) return 0 ;; esac
  return 1
}

# Change directory without triggering hooks (chpwd, auto-ls...) or CDPATH.
_pingo_cd_quiet() {
  if [ -n "${ZSH_VERSION:-}" ]; then
    builtin cd -q -- "$1"
  else
    CDPATH= builtin cd -- "$1"
  fi
}

# _pingo_fmt KEY [args...] -> formatted message in $_PINGO_M
_pingo_fmt() {
  local _pk=$1 _pf=
  shift
  eval "_pf=\${PINGO_MSG_$_pk-}"
  [ -n "$_pf" ] || _pf=$_pk
  printf -v _PINGO_M "$_pf" "$@"
}

_pingo_ok() { printf '%s✓%s %s\n' "${_C_GRN}" "${_C_R}" "$1"; }
_pingo_info() { printf '%s•%s %s\n' "${_C_CYN}" "${_C_R}" "$1"; }
_pingo_warn() { printf '%s!%s %s\n' "${_C_YEL}" "${_C_R}" "$1" >&2; }
_pingo_fail() { printf '%s✗%s %s\n' "${_C_RED}" "${_C_R}" "$1" >&2; }

_pingo_is_yes() {
  case "$1" in y | Y | yes | Yes | YES | s | S | sim | Sim | SIM) return 0 ;; esac
  return 1
}

# Single ASCII letter to lower case -> $_PINGO_LOWER
_pingo_lower_char() {
  local up=ABCDEFGHIJKLMNOPQRSTUVWXYZ lo=abcdefghijklmnopqrstuvwxyz pre
  case "$up" in
    *"$1"*)
      pre=${up%%"$1"*}
      _PINGO_LOWER=${lo:${#pre}:1}
      ;;
    *) _PINGO_LOWER=$1 ;;
  esac
}

# Whole string to lower case (ASCII) -> $_PINGO_LOWS
_pingo_lower() {
  local s=$1 c out=
  while [ -n "$s" ]; do
    c=${s:0:1}
    s=${s:1}
    _pingo_lower_char "$c"
    out="$out$_PINGO_LOWER"
  done
  _PINGO_LOWS=$out
}

_pingo_basename() {
  local p=$1
  while :; do
    case "$p" in
      */) [ "$p" = / ] && break; p=${p%/} ;;
      *) break ;;
    esac
  done
  case "$p" in
    /) _PINGO_BN=/ ;;
    *) _PINGO_BN=${p##*/} ;;
  esac
}

# Replace $HOME with ~ for display -> $_PINGO_TL
_pingo_tilde() {
  case "$1" in
    "$HOME") _PINGO_TL="~" ;;
    "$HOME"/*) _PINGO_TL="~${1#"$HOME"}" ;;
    *) _PINGO_TL=$1 ;;
  esac
}

# Strip leading zeros of a number string -> $_PINGO_NUM (empty if not a number)
_pingo_number() {
  local n=$1
  case "$n" in '' | *[!0-9]*) _PINGO_NUM= ; return 1 ;; esac
  while :; do
    case "$n" in 0?*) n=${n#0} ;; *) break ;; esac
  done
  _PINGO_NUM=$n
}

_pingo_pad() { # text width -> $_PINGO_PAD (left aligned)
  local s=$1
  while [ "${#s}" -lt "$2" ]; do s="$s "; done
  _PINGO_PAD=$s
}

_pingo_padl() { # text width -> $_PINGO_PAD (right aligned)
  local s=$1
  while [ "${#s}" -lt "$2" ]; do s=" $s"; done
  _PINGO_PAD=$s
}

# --- paths --------------------------------------------------------------------

# Windows path (C:\a\b, C:/a/b) to POSIX form (/c/a/b) -> $_PINGO_WP
_pingo_winpath() {
  local p=$1 d
  p=${p//\\//}
  case "$p" in
    [A-Za-z]: | [A-Za-z]:/*)
      d=${p%%:*}
      p=${p#?:}
      _pingo_lower_char "$d"
      p="/$_PINGO_LOWER$p"
      ;;
  esac
  _PINGO_WP=$p
}

# Normalize a user supplied path to an absolute POSIX path -> $_PINGO_NP
# Returns 1 if it is not an existing directory.
_pingo_normpath() {
  local p=$1
  [ -n "$p" ] || return 1
  if _pingo_is_windows; then
    _pingo_winpath "$p"
    p=$_PINGO_WP
  fi
  case "$p" in
    "~") p=$HOME ;;
    "~/"*) p="$HOME/${p#??}" ;;
  esac
  [ -d "$p" ] || return 1
  _PINGO_NP=$(
    CDPATH=
    _pingo_cd_quiet "$p" && pwd
  ) || return 1
  [ -n "$_PINGO_NP" ]
}

# Key used to compare paths (case-insensitive on Windows) -> $_PINGO_PK
_pingo_pathkey() {
  if _pingo_is_windows; then
    _pingo_lower "$1"
    _PINGO_PK=$_PINGO_LOWS
  else
    _PINGO_PK=$1
  fi
}

# Current git branch read straight from .git/HEAD (no git call) -> $_PINGO_BR
_pingo_branch() {
  local d=$1 g= h= l=
  _PINGO_BR=
  if [ -d "$d/.git" ]; then
    g="$d/.git"
  elif [ -f "$d/.git" ]; then
    IFS= read -r l <"$d/.git"
    l=${l%$'\r'}
    case "$l" in
      "gitdir: "*) g=${l#gitdir: } ;;
      *) return 1 ;;
    esac
    if _pingo_is_windows; then
      _pingo_winpath "$g"
      g=$_PINGO_WP
    fi
    case "$g" in /*) ;; *) g="$d/$g" ;; esac
  else
    return 1
  fi
  [ -f "$g/HEAD" ] || return 1
  IFS= read -r h <"$g/HEAD"
  h=${h%$'\r'}
  case "$h" in
    "ref: refs/heads/"*) _PINGO_BR=${h#ref: refs/heads/} ;;
    "ref: "*) _PINGO_BR=${h#ref: } ;;
    "") return 1 ;;
    *) _PINGO_BR=${h:0:7} ;;
  esac
  return 0
}

# --- configuration --------------------------------------------------------------

_pingo_config_get() { # key -> $_PINGO_VAL
  local line= k
  _PINGO_VAL=
  [ -f "$_PINGO_CONFIG" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    case "$line" in '' | '#'*) continue ;; esac
    k=${line%%=*}
    if [ "$k" = "$1" ]; then
      _PINGO_VAL=${line#*=}
      return 0
    fi
  done <"$_PINGO_CONFIG"
  return 1
}

_pingo_config_template() {
  printf '%s\n' \
    "# pingo configuration" \
    "# Edit this file, run \`pingo config\`, or press \"s\" in the pingo menu." \
    "" \
    "# Interface language: en, pt-BR, or any <code>.sh placed in:" \
    "#   $_PINGO_DATA/lang/" \
    "lang=en"
}

_pingo_config_set() { # key value
  local line= k out= found=0
  [ -d "$_PINGO_DATA" ] || mkdir -p "$_PINGO_DATA" || return 1
  [ -f "$_PINGO_CONFIG" ] || _pingo_config_template >"$_PINGO_CONFIG" || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    case "$line" in
      '' | '#'*) ;;
      *)
        k=${line%%=*}
        if [ "$k" = "$1" ] && [ "$found" -eq 0 ]; then
          line="$1=$2"
          found=1
        fi
        ;;
    esac
    out="$out$line$_PINGO_NL"
  done <"$_PINGO_CONFIG"
  [ "$found" -eq 1 ] || out="$out$1=$2$_PINGO_NL"
  printf '%s' "$out" >"$_PINGO_CONFIG"
}

# --- languages ------------------------------------------------------------------

_pingo_windows_locale() {
  local line out=
  while IFS= read -r line; do
    line=${line%$'\r'}
    case "$line" in *LocaleName*) out=${line##* } ;; esac
  done <<EOF
$(MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' reg.exe query 'HKCU\Control Panel\International' /v LocaleName 2>/dev/null)
EOF
  _PINGO_WINLOC=$out
}

# Guess the language from the OS -> $_PINGO_DETECTED (pt-BR | en)
_pingo_detect_lang() {
  local l="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
  case "$l" in
    '' | C | C.* | POSIX)
      if _pingo_is_windows; then
        _pingo_windows_locale
        l=$_PINGO_WINLOC
      fi
      ;;
  esac
  case "$l" in
    pt* | PT*) _PINGO_DETECTED=pt-BR ;;
    *) _PINGO_DETECTED=en ;;
  esac
}

_pingo_lang_file() { # code -> $_PINGO_LF
  _PINGO_LF=
  case "$1" in '' | *[!A-Za-z0-9_-]*) return 1 ;; esac
  if [ -f "$_PINGO_DATA/lang/$1.sh" ]; then
    _PINGO_LF="$_PINGO_DATA/lang/$1.sh"
  elif [ -f "$PINGO_HOME/lang/$1.sh" ]; then
    _PINGO_LF="$PINGO_HOME/lang/$1.sh"
  else
    return 1
  fi
}

_pingo_load_lang() {
  local lang=
  if _pingo_config_get lang && [ -n "$_PINGO_VAL" ]; then
    lang=$_PINGO_VAL
  else
    _pingo_detect_lang
    lang=$_PINGO_DETECTED
  fi
  # English is always loaded first: missing keys fall back to it.
  . "$PINGO_HOME/lang/en.sh"
  if [ "$lang" != en ] && _pingo_lang_file "$lang"; then
    . "$_PINGO_LF"
  elif [ "$lang" != en ]; then
    lang=en
  fi
  _PINGO_LANG=$lang
}

# Available languages, newline separated -> $_PINGO_LANGS
_pingo_langs() {
  local f c out=
  for f in "$_PINGO_DATA"/lang/*.sh "$PINGO_HOME"/lang/*.sh; do
    [ -f "$f" ] || continue
    c=${f##*/}
    c=${c%.sh}
    case "$_PINGO_NL$out" in *"$_PINGO_NL$c$_PINGO_NL"*) continue ;; esac
    out="$out$c$_PINGO_NL"
  done
  _PINGO_LANGS=$out
}

# Human readable name of a language -> $_PINGO_LNAME
_pingo_lang_name() {
  local line=
  _PINGO_LNAME=$1
  _pingo_lang_file "$1" || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      PINGO_LANG_NAME=*)
        line=${line#PINGO_LANG_NAME=}
        line=${line#[\"\']}
        line=${line%[\"\']}
        _PINGO_LNAME=$line
        return 0
        ;;
    esac
  done <"$_PINGO_LF"
}

# --- init -----------------------------------------------------------------------

_pingo_init() {
  _PINGO_DATA="${PINGO_DATA_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/pingo}"
  _PINGO_REPOS="$_PINGO_DATA/repos"
  _PINGO_CONFIG="$_PINGO_DATA/config"
  if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != dumb ]; then
    _C_R=$'\033[0m' _C_B=$'\033[1m' _C_D=$'\033[2m'
    _C_RED=$'\033[31m' _C_GRN=$'\033[32m' _C_YEL=$'\033[33m'
    _C_MAG=$'\033[35m' _C_CYN=$'\033[36m'
  else
    _C_R= _C_B= _C_D= _C_RED= _C_GRN= _C_YEL= _C_MAG= _C_CYN=
  fi
  if [ -n "${BASH_VERSION:-}" ] && [ "${BASH_VERSION%%.*}" -lt 4 ]; then
    _PINGO_ESC_T=1 # bash 3.2 has no fractional read timeouts
  else
    _PINGO_ESC_T=0.1
  fi
  _pingo_load_lang
}

# --- repository list ----------------------------------------------------------
# File format: one entry per line, "alias|path". The alias may be empty.
# The line order IS the position of the repository.

_pingo_load() {
  local line=
  _PINGO_LIST=
  _PINGO_N=0
  [ -f "$_PINGO_REPOS" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    case "$line" in
      '' | '#'*) continue ;;
      *"|"*) ;;
      *) line="|$line" ;;
    esac
    _PINGO_LIST="$_PINGO_LIST$line$_PINGO_NL"
    _PINGO_N=$((_PINGO_N + 1))
  done <"$_PINGO_REPOS"
}

_pingo_save() {
  [ -d "$_PINGO_DATA" ] || mkdir -p "$_PINGO_DATA" || return 1
  printf '%s' "$_PINGO_LIST" >"$_PINGO_REPOS"
}

# Entry i -> $_PINGO_L (raw line), $_PINGO_A (alias), $_PINGO_P (path),
#            $_PINGO_NAME (alias or folder name)
_pingo_get() {
  local rest=$_PINGO_LIST c=0
  while [ -n "$rest" ]; do
    _PINGO_L=${rest%%"$_PINGO_NL"*}
    rest=${rest#*"$_PINGO_NL"}
    c=$((c + 1))
    if [ "$c" -eq "$1" ]; then
      _PINGO_A=${_PINGO_L%%"|"*}
      _PINGO_P=${_PINGO_L#*"|"}
      if [ -n "$_PINGO_A" ]; then
        _PINGO_NAME=$_PINGO_A
      else
        _pingo_basename "$_PINGO_P"
        _PINGO_NAME=$_PINGO_BN
      fi
      return 0
    fi
  done
  return 1
}

_pingo_list_remove() { # i
  local rest=$_PINGO_LIST out= c=0 l
  while [ -n "$rest" ]; do
    l=${rest%%"$_PINGO_NL"*}
    rest=${rest#*"$_PINGO_NL"}
    c=$((c + 1))
    [ "$c" -eq "$1" ] || out="$out$l$_PINGO_NL"
  done
  _PINGO_LIST=$out
  _PINGO_N=$((_PINGO_N - 1))
}

_pingo_list_insert() { # line position
  local rest=$_PINGO_LIST out= c=0 l
  while [ -n "$rest" ]; do
    l=${rest%%"$_PINGO_NL"*}
    rest=${rest#*"$_PINGO_NL"}
    c=$((c + 1))
    [ "$c" -eq "$2" ] && out="$out$1$_PINGO_NL"
    out="$out$l$_PINGO_NL"
  done
  [ "$2" -gt "$c" ] && out="$out$1$_PINGO_NL"
  _PINGO_LIST=$out
  _PINGO_N=$((_PINGO_N + 1))
}

_pingo_list_replace() { # i line
  local rest=$_PINGO_LIST out= c=0 l
  while [ -n "$rest" ]; do
    l=${rest%%"$_PINGO_NL"*}
    rest=${rest#*"$_PINGO_NL"}
    c=$((c + 1))
    if [ "$c" -eq "$1" ]; then out="$out$2$_PINGO_NL"; else out="$out$l$_PINGO_NL"; fi
  done
  _PINGO_LIST=$out
}

_pingo_list_move() { # from to
  local line
  _pingo_get "$1" || return 1
  line=$_PINGO_L
  _pingo_list_remove "$1"
  _pingo_list_insert "$line" "$2"
}

# Resolve "3", "alias" or "folder-name" to a position -> $_PINGO_IDX
_pingo_resolve() {
  local i=1 hits=0 hit=0
  _PINGO_IDX=
  if _pingo_number "$1"; then
    if [ "$_PINGO_NUM" -ge 1 ] && [ "$_PINGO_NUM" -le "$_PINGO_N" ]; then
      _PINGO_IDX=$_PINGO_NUM
      return 0
    fi
    _pingo_fmt ERR_NO_POSITION "$1" "$_PINGO_N"
    return 1
  fi
  while [ "$i" -le "$_PINGO_N" ]; do
    _pingo_get "$i"
    if [ "$_PINGO_A" = "$1" ]; then
      _PINGO_IDX=$i
      return 0
    fi
    i=$((i + 1))
  done
  i=1
  while [ "$i" -le "$_PINGO_N" ]; do
    _pingo_get "$i"
    if [ -z "$_PINGO_A" ] && [ "$_PINGO_NAME" = "$1" ]; then
      hits=$((hits + 1))
      hit=$i
    fi
    i=$((i + 1))
  done
  if [ "$hits" -eq 1 ]; then
    _PINGO_IDX=$hit
    return 0
  elif [ "$hits" -gt 1 ]; then
    _pingo_fmt ERR_AMBIGUOUS "$1"
  else
    _pingo_fmt ERR_NOT_FOUND "$1"
  fi
  return 1
}

# Validate an alias. $2 = position to ignore (when renaming), 0 for none.
_pingo_check_alias() {
  local i=1
  case "$1" in
    '') _pingo_fmt ERR_ALIAS_EMPTY; return 1 ;;
    *[!0-9]*) ;;
    *) _pingo_fmt ERR_ALIAS_NUMERIC "$1"; return 1 ;;
  esac
  case "$1" in
    *" "* | *"|"* | *"	"* | -*) _pingo_fmt ERR_ALIAS_CHARS "$1"; return 1 ;;
  esac
  case "$_PINGO_RESERVED" in
    *" $1 "*) _pingo_fmt ERR_ALIAS_RESERVED "$1"; return 1 ;;
  esac
  while [ "$i" -le "$_PINGO_N" ]; do
    if [ "$i" -ne "$2" ]; then
      _pingo_get "$i"
      if [ "$_PINGO_NAME" = "$1" ]; then
        _pingo_fmt ERR_ALIAS_TAKEN "$1" "$i"
        return 1
      fi
    fi
    i=$((i + 1))
  done
  return 0
}

# --- operations (no printing; message in $_PINGO_M, warning in $_PINGO_W) -------

_pingo_check_new_path() { # raw-path -> $_PINGO_NP
  local i=1 key
  if ! _pingo_normpath "$1"; then
    _pingo_fmt ERR_NOT_DIR "$1"
    return 1
  fi
  _pingo_pathkey "$_PINGO_NP"
  key=$_PINGO_PK
  while [ "$i" -le "$_PINGO_N" ]; do
    _pingo_get "$i"
    _pingo_pathkey "$_PINGO_P"
    if [ "$_PINGO_PK" = "$key" ]; then
      _pingo_tilde "$_PINGO_P"
      _pingo_fmt ERR_DUP_PATH "$_PINGO_TL" "$i" "$_PINGO_NAME"
      return 1
    fi
    i=$((i + 1))
  done
  return 0
}

_pingo_op_add() { # raw-path [alias]
  local np
  _PINGO_W=
  _pingo_check_new_path "$1" || return 1
  np=$_PINGO_NP
  if [ -n "${2:-}" ]; then
    _pingo_check_alias "$2" 0 || return 1
  fi
  if [ ! -e "$np/.git" ]; then
    _pingo_tilde "$np"
    _pingo_fmt WARN_NOT_GIT "$_PINGO_TL"
    _PINGO_W=$_PINGO_M
  fi
  _PINGO_LIST="$_PINGO_LIST${2:-}|$np$_PINGO_NL"
  _PINGO_N=$((_PINGO_N + 1))
  if ! _pingo_save; then
    _pingo_fmt ERR_SAVE "$_PINGO_REPOS"
    return 1
  fi
  _pingo_get "$_PINGO_N"
  _pingo_tilde "$np"
  _pingo_fmt ADDED "$_PINGO_N" "$_PINGO_NAME" "$_PINGO_TL"
}

_pingo_op_remove() { # i
  local nm
  _pingo_get "$1" || return 1
  nm=$_PINGO_NAME
  _pingo_list_remove "$1"
  if ! _pingo_save; then
    _pingo_fmt ERR_SAVE "$_PINGO_REPOS"
    return 1
  fi
  _pingo_fmt REMOVED "$nm"
}

_pingo_op_move() { # from to
  _pingo_get "$1" || return 1
  _pingo_list_move "$1" "$2"
  if ! _pingo_save; then
    _pingo_fmt ERR_SAVE "$_PINGO_REPOS"
    return 1
  fi
  _pingo_fmt MOVED "$_PINGO_NAME" "$2"
}

_pingo_op_rename() { # i alias
  local old
  _pingo_check_alias "$2" "$1" || return 1
  _pingo_get "$1" || return 1
  old=$_PINGO_NAME
  _pingo_list_replace "$1" "$2|$_PINGO_P"
  if ! _pingo_save; then
    _pingo_fmt ERR_SAVE "$_PINGO_REPOS"
    return 1
  fi
  _pingo_fmt RENAMED "$old" "$2"
}

# --- rendering ------------------------------------------------------------------

# Column widths for the current list -> $_PINGO_IW (index), $_PINGO_NW (name),
# $_PINGO_PW (path). Paths are only truncated when writing to a terminal.
_pingo_layout() {
  local i=1 w=4 pw=0 bw=0 lb avail cols
  _pingo_fmt NOT_FOUND
  while [ "$i" -le "$_PINGO_N" ]; do
    _pingo_get "$i"
    [ "${#_PINGO_NAME}" -gt "$w" ] && w=${#_PINGO_NAME}
    _pingo_tilde "$_PINGO_P"
    [ "${#_PINGO_TL}" -gt "$pw" ] && pw=${#_PINGO_TL}
    lb=0
    if [ ! -d "$_PINGO_P" ]; then
      lb=$((${#_PINGO_M} + 2))
    elif _pingo_branch "$_PINGO_P"; then
      lb=$((${#_PINGO_BR} + 2))
      [ "$lb" -gt 30 ] && lb=30
    fi
    [ "$lb" -gt "$bw" ] && bw=$lb
    i=$((i + 1))
  done
  [ "$w" -gt 24 ] && w=24
  _PINGO_NW=$w
  _PINGO_IW=${#_PINGO_N}
  if [ -t 1 ]; then
    cols=${COLUMNS:-80}
    [ "$cols" -lt 40 ] && cols=40
    avail=$((cols - 6 - _PINGO_IW - 2 - _PINGO_NW - 2 - bw - 1))
    [ "$avail" -lt 10 ] && avail=10
    [ "$pw" -gt "$avail" ] && pw=$avail
  fi
  _PINGO_PW=$pw
}

# Row for entry i; mode: 0 plain, 1 selected, 2 being moved -> $_PINGO_ROW
_pingo_row() {
  local mk=" " nm ix pth info= ic pc nc=${_C_B} k
  _pingo_get "$1"
  _pingo_padl "$1" "$_PINGO_IW"
  ix=$_PINGO_PAD
  nm=$_PINGO_NAME
  if [ "${#nm}" -gt "$_PINGO_NW" ]; then
    k=$((_PINGO_NW - 1))
    nm="${nm:0:$k}…"
  fi
  _pingo_pad "$nm" "$_PINGO_NW"
  nm=$_PINGO_PAD
  if [ -d "$_PINGO_P" ]; then
    if _pingo_branch "$_PINGO_P"; then
      [ "${#_PINGO_BR}" -gt 28 ] && _PINGO_BR="${_PINGO_BR:0:27}…"
      info="⎇ $_PINGO_BR"
    fi
    ic=${_C_MAG}
    pc=${_C_D}
  else
    _pingo_fmt NOT_FOUND
    info="✗ $_PINGO_M"
    ic=${_C_RED}
    pc=${_C_RED}
  fi
  _pingo_tilde "$_PINGO_P"
  pth=$_PINGO_TL
  if [ "${#pth}" -gt "$_PINGO_PW" ]; then
    k=$((${#pth} - _PINGO_PW + 1))
    pth="…${pth:$k}"
  fi
  if [ -n "$info" ]; then
    _pingo_pad "$pth" "$_PINGO_PW"
    pth="$_PINGO_PAD  "
  fi
  case "$2" in
    1) mk="${_C_CYN}${_C_B}❯${_C_R}"; nc="${_C_CYN}${_C_B}" ;;
    2) mk="${_C_YEL}${_C_B}↕${_C_R}"; nc="${_C_YEL}${_C_B}" ;;
  esac
  if [ -n "$info" ]; then
    _PINGO_ROW="  $mk ${_C_D}$ix${_C_R}  $nc$nm${_C_R}  $pc$pth${_C_R}$ic$info${_C_R}"
  else
    _PINGO_ROW="  $mk ${_C_D}$ix${_C_R}  $nc$nm${_C_R}  $pc$pth${_C_R}"
  fi
}

_pingo_empty_hint() {
  _pingo_fmt EMPTY
  printf '  %s\n' "$_PINGO_M"
  _pingo_fmt EMPTY_HINT "${_C_B}pingo add <path> [alias]${_C_R}"
  printf '  %s%s%s\n' "${_C_D}" "$_PINGO_M" "${_C_R}"
}

# --- commands -------------------------------------------------------------------

_pingo_go() { # i
  _pingo_get "$1" || return 1
  if [ ! -d "$_PINGO_P" ]; then
    _pingo_tilde "$_PINGO_P"
    _pingo_fmt ERR_MISSING_DIR "$_PINGO_NAME" "$_PINGO_TL"
    _pingo_fail "$_PINGO_M"
    _pingo_fmt HINT_PRUNE
    printf '  %s%s%s\n' "${_C_D}" "$_PINGO_M" "${_C_R}" >&2
    return 1
  fi
  builtin cd -- "$_PINGO_P" || return 1
  _pingo_tilde "$_PINGO_P"
  printf '%s→%s %s%s%s %s%s%s\n' "${_C_CYN}" "${_C_R}" "${_C_B}" "$_PINGO_NAME" "${_C_R}" "${_C_D}" "$_PINGO_TL" "${_C_R}"
}

_pingo_cmd_go() {
  _pingo_load
  if ! _pingo_resolve "$1"; then
    _pingo_fail "$_PINGO_M"
    return 1
  fi
  _pingo_go "$_PINGO_IDX"
}

_pingo_cmd_ls() {
  local i=1
  _pingo_load
  if [ "$_PINGO_N" -eq 0 ]; then
    _pingo_empty_hint
    return 0
  fi
  _pingo_layout
  while [ "$i" -le "$_PINGO_N" ]; do
    _pingo_row "$i" 0
    printf '%s\n' "$_PINGO_ROW"
    i=$((i + 1))
  done
}

_pingo_cmd_add() {
  if [ -z "${1:-}" ] || [ $# -gt 2 ]; then
    _pingo_fmt USAGE "pingo add <path> [alias]"
    _pingo_fail "$_PINGO_M"
    return 2
  fi
  _pingo_load
  if ! _pingo_op_add "$1" "${2:-}"; then
    _pingo_fail "$_PINGO_M"
    return 1
  fi
  [ -n "$_PINGO_W" ] && _pingo_warn "$_PINGO_W"
  _pingo_ok "$_PINGO_M"
}

_pingo_cmd_rm() {
  local yes=0 tgt= a ans=
  for a in "$@"; do
    case "$a" in
      -y | --yes) yes=1 ;;
      *) tgt=$a ;;
    esac
  done
  if [ -z "$tgt" ]; then
    _pingo_fmt USAGE "pingo rm <n|alias> [-y]"
    _pingo_fail "$_PINGO_M"
    return 2
  fi
  _pingo_load
  if ! _pingo_resolve "$tgt"; then
    _pingo_fail "$_PINGO_M"
    return 1
  fi
  if [ "$yes" -eq 0 ]; then
    _pingo_get "$_PINGO_IDX"
    _pingo_tilde "$_PINGO_P"
    _pingo_fmt CONFIRM_REMOVE "$_PINGO_IDX" "${_C_B}$_PINGO_NAME${_C_R} ${_C_D}($_PINGO_TL)${_C_R}"
    printf '%s?%s %s ' "${_C_YEL}" "${_C_R}" "$_PINGO_M"
    read -r ans || ans=
    if ! _pingo_is_yes "$ans"; then
      _pingo_fmt CANCELLED
      _pingo_info "$_PINGO_M"
      return 1
    fi
  fi
  if ! _pingo_op_remove "$_PINGO_IDX"; then
    _pingo_fail "$_PINGO_M"
    return 1
  fi
  _pingo_ok "$_PINGO_M"
}

_pingo_cmd_mv() {
  local from
  if [ $# -ne 2 ]; then
    _pingo_fmt USAGE "pingo mv <n|alias> <position>"
    _pingo_fail "$_PINGO_M"
    return 2
  fi
  _pingo_load
  if ! _pingo_resolve "$1"; then
    _pingo_fail "$_PINGO_M"
    return 1
  fi
  from=$_PINGO_IDX
  if ! _pingo_number "$2" || [ "$_PINGO_NUM" -lt 1 ] || [ "$_PINGO_NUM" -gt "$_PINGO_N" ]; then
    _pingo_fmt ERR_NO_POSITION "$2" "$_PINGO_N"
    _pingo_fail "$_PINGO_M"
    return 1
  fi
  if ! _pingo_op_move "$from" "$_PINGO_NUM"; then
    _pingo_fail "$_PINGO_M"
    return 1
  fi
  _pingo_ok "$_PINGO_M"
}

_pingo_cmd_rename() {
  if [ $# -ne 2 ]; then
    _pingo_fmt USAGE "pingo rename <n|alias> <new-alias>"
    _pingo_fail "$_PINGO_M"
    return 2
  fi
  _pingo_load
  if ! _pingo_resolve "$1"; then
    _pingo_fail "$_PINGO_M"
    return 1
  fi
  if ! _pingo_op_rename "$_PINGO_IDX" "$2"; then
    _pingo_fail "$_PINGO_M"
    return 1
  fi
  _pingo_ok "$_PINGO_M"
}

_pingo_cmd_prune() {
  local i count=0
  _pingo_load
  i=$_PINGO_N
  while [ "$i" -ge 1 ]; do
    _pingo_get "$i"
    if [ ! -d "$_PINGO_P" ]; then
      _pingo_tilde "$_PINGO_P"
      _pingo_fmt PRUNED_ONE "$_PINGO_NAME" "$_PINGO_TL"
      _pingo_info "$_PINGO_M"
      _pingo_list_remove "$i"
      count=$((count + 1))
    fi
    i=$((i - 1))
  done
  if [ "$count" -eq 0 ]; then
    _pingo_fmt PRUNE_NOTHING
    _pingo_ok "$_PINGO_M"
    return 0
  fi
  if ! _pingo_save; then
    _pingo_fmt ERR_SAVE "$_PINGO_REPOS"
    _pingo_fail "$_PINGO_M"
    return 1
  fi
  _pingo_fmt PRUNED "$count"
  _pingo_ok "$_PINGO_M"
}

_pingo_cmd_config() {
  local rest c mark
  case "${1:-}" in
    '')
      _pingo_lang_name "$_PINGO_LANG"
      printf '  %s%-10s%s %s\n' "${_C_D}" "lang" "${_C_R}" "$_PINGO_LANG ($_PINGO_LNAME)"
      _pingo_tilde "$_PINGO_CONFIG"
      printf '  %s%-10s%s %s\n' "${_C_D}" "config" "${_C_R}" "$_PINGO_TL"
      _pingo_tilde "$_PINGO_REPOS"
      printf '  %s%-10s%s %s\n' "${_C_D}" "repos" "${_C_R}" "$_PINGO_TL"
      _pingo_tilde "$PINGO_HOME"
      printf '  %s%-10s%s %s\n' "${_C_D}" "install" "${_C_R}" "$_PINGO_TL"
      ;;
    lang)
      if [ -z "${2:-}" ]; then
        _pingo_langs
        rest=$_PINGO_LANGS
        while [ -n "$rest" ]; do
          c=${rest%%"$_PINGO_NL"*}
          rest=${rest#*"$_PINGO_NL"}
          _pingo_lang_name "$c"
          if [ "$c" = "$_PINGO_LANG" ]; then mark="${_C_GRN}●${_C_R}"; else mark=" "; fi
          printf '  %s %-8s %s%s%s\n' "$mark" "$c" "${_C_D}" "$_PINGO_LNAME" "${_C_R}"
        done
        return 0
      fi
      if ! _pingo_lang_file "$2"; then
        _pingo_fmt ERR_UNKNOWN_LANG "$2"
        _pingo_fail "$_PINGO_M"
        return 1
      fi
      if ! _pingo_config_set lang "$2"; then
        _pingo_fmt ERR_SAVE "$_PINGO_CONFIG"
        _pingo_fail "$_PINGO_M"
        return 1
      fi
      _pingo_load_lang
      _pingo_lang_name "$2"
      _pingo_fmt LANG_SET "$_PINGO_LNAME"
      _pingo_ok "$_PINGO_M"
      ;;
    *)
      _pingo_fmt USAGE "pingo config [lang [code]]"
      _pingo_fail "$_PINGO_M"
      return 2
      ;;
  esac
}

# Fails (with the shared message) when git is not on PATH.
_pingo_require_git() {
  command -v git >/dev/null 2>&1 && return 0
  _pingo_fmt ERR_NO_GIT
  _pingo_fail "$_PINGO_M"
  return 1
}

_pingo_cmd_update() {
  _pingo_require_git || return 1
  if [ ! -d "$PINGO_HOME/.git" ]; then
    _pingo_tilde "$PINGO_HOME"
    _pingo_fmt ERR_NOT_CLONE "$_PINGO_TL"
    _pingo_fail "$_PINGO_M"
    return 1
  fi
  _pingo_fmt UPDATING
  _pingo_info "$_PINGO_M"
  if ! git -C "$PINGO_HOME" pull --ff-only; then
    _pingo_fmt UPDATE_FAILED
    _pingo_fail "$_PINGO_M"
    return 1
  fi
  . "$PINGO_HOME/pingo.sh"
  _pingo_fmt UPDATED "$PINGO_VERSION"
  _pingo_ok "$_PINGO_M"
}

# --- Pull ---------------------------------------------------------------------------
# The only place pingo runs git over registered Repositories. Never merges,
# rebases, stashes, checks out or creates commits: fast-forward only.

# git in the Repository being pulled, never prompting for credentials.
_pingo_pull_git() {
  GIT_TERMINAL_PROMPT=0 git -C "$_PINGO_PULL_DIR" "$@"
}

# Pull core: brings the Default branch of the Repository at <dir> up to date.
#   _PINGO_PULL_RES     updated | current | failed
#   _PINGO_PULL_BRANCH  Default branch name
#   _PINGO_PULL_COUNT   commits received (updated)
#   _PINGO_PULL_OLD/NEW short hashes before/after (updated)
# Returns 0 for updated/current, 1 otherwise.
_pingo_pull_one() {
  local db= remote= head= old= new= ref=
  _PINGO_PULL_DIR=$1 _PINGO_PULL_RES=failed _PINGO_PULL_BRANCH=
  _PINGO_PULL_COUNT=0 _PINGO_PULL_OLD= _PINGO_PULL_NEW=

  # Default branch: the remote's declared HEAD, else main, else master.
  ref=$(_pingo_pull_git symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null)
  if [ -n "$ref" ]; then
    db=${ref#refs/remotes/origin/}
  elif _pingo_pull_git show-ref -q --verify refs/heads/main 2>/dev/null; then
    db=main
  elif _pingo_pull_git show-ref -q --verify refs/heads/master 2>/dev/null; then
    db=master
  else
    return 1
  fi
  _PINGO_PULL_BRANCH=$db

  # Remote: the Default branch's upstream, else origin.
  remote=$(_pingo_pull_git config --get "branch.$db.remote" 2>/dev/null)
  [ -n "$remote" ] || remote=origin

  old=$(_pingo_pull_git rev-parse -q --verify "refs/heads/$db" 2>/dev/null)
  head=$(_pingo_pull_git symbolic-ref -q HEAD 2>/dev/null)
  if [ "$head" = "refs/heads/$db" ]; then
    _pingo_pull_git -c pull.rebase=false pull -q --ff-only --no-rebase "$remote" "$db" >/dev/null 2>&1 || return 1
  else
    # Fetching straight into the local ref only accepts fast-forwards.
    _pingo_pull_git fetch -q "$remote" "$db:$db" >/dev/null 2>&1 || return 1
  fi
  new=$(_pingo_pull_git rev-parse -q --verify "refs/heads/$db" 2>/dev/null)

  if [ "$old" = "$new" ]; then
    _PINGO_PULL_RES=current
    return 0
  fi
  _PINGO_PULL_RES=updated
  if [ -n "$old" ]; then
    _PINGO_PULL_COUNT=$(_pingo_pull_git rev-list --count "$old..$new" 2>/dev/null)
    _PINGO_PULL_OLD=$(_pingo_pull_git rev-parse --short "$old" 2>/dev/null)
  else
    _PINGO_PULL_COUNT=$(_pingo_pull_git rev-list --count "$new" 2>/dev/null)
  fi
  _PINGO_PULL_NEW=$(_pingo_pull_git rev-parse --short "$new" 2>/dev/null)
  return 0
}

# Prints the result line of the last Pull of <name>.
_pingo_pull_report() {
  case "$_PINGO_PULL_RES" in
    updated)
      if [ "$_PINGO_PULL_COUNT" = 1 ]; then
        _pingo_fmt PULL_UPDATED_ONE "$1" "$_PINGO_PULL_BRANCH" "$_PINGO_PULL_OLD" "$_PINGO_PULL_NEW"
      else
        _pingo_fmt PULL_UPDATED_MANY "$1" "$_PINGO_PULL_BRANCH" "$_PINGO_PULL_COUNT" "$_PINGO_PULL_OLD" "$_PINGO_PULL_NEW"
      fi
      _pingo_ok "$_PINGO_M"
      ;;
    current)
      _pingo_fmt PULL_CURRENT "$1" "$_PINGO_PULL_BRANCH"
      _pingo_ok "$_PINGO_M"
      ;;
    *)
      _pingo_fmt PULL_FAILED "$1"
      _pingo_fail "$_PINGO_M"
      ;;
  esac
}

_pingo_cmd_pull() {
  if [ $# -ne 1 ]; then
    _pingo_fmt USAGE "pingo pull <n|alias>"
    _pingo_fail "$_PINGO_M"
    return 2
  fi
  _pingo_require_git || return 1
  _pingo_load
  if ! _pingo_resolve "$1"; then
    _pingo_fail "$_PINGO_M"
    return 1
  fi
  _pingo_get "$_PINGO_IDX"
  _pingo_pull_one "$_PINGO_P"
  _pingo_pull_report "$_PINGO_NAME"
  [ "$_PINGO_PULL_RES" = updated ] || [ "$_PINGO_PULL_RES" = current ]
}

_pingo_help_line() { # command description
  _pingo_pad "$1" 32
  printf '    %s%s%s%s\n' "${_C_CYN}" "$_PINGO_PAD" "${_C_R}" "$2"
}

_pingo_cmd_help() {
  _pingo_fmt HELP_TAGLINE
  printf '\n  %s%spingo%s %s— %s%s  %sv%s%s\n\n' "${_C_B}" "${_C_CYN}" "${_C_R}" "${_C_D}" "${_C_R}" "$_PINGO_M" "${_C_D}" "$PINGO_VERSION" "${_C_R}"
  _pingo_fmt HELP_USAGE
  printf '  %s%s%s\n' "${_C_B}" "$_PINGO_M" "${_C_R}"
  _pingo_fmt HELP_MENU;    _pingo_help_line "pingo" "$_PINGO_M"
  _pingo_fmt HELP_GO;      _pingo_help_line "pingo <n|alias>" "$_PINGO_M"
  _pingo_fmt HELP_LS;      _pingo_help_line "pingo ls" "$_PINGO_M"
  _pingo_fmt HELP_ADD;     _pingo_help_line "pingo add <path> [alias]" "$_PINGO_M"
  _pingo_fmt HELP_RM;      _pingo_help_line "pingo rm <n|alias> [-y]" "$_PINGO_M"
  _pingo_fmt HELP_MV;      _pingo_help_line "pingo mv <n|alias> <pos>" "$_PINGO_M"
  _pingo_fmt HELP_RENAME;  _pingo_help_line "pingo rename <n|alias> <new>" "$_PINGO_M"
  _pingo_fmt HELP_PRUNE;   _pingo_help_line "pingo prune" "$_PINGO_M"
  _pingo_fmt HELP_CONFIG;  _pingo_help_line "pingo config" "$_PINGO_M"
  _pingo_fmt HELP_LANG;    _pingo_help_line "pingo config lang [code]" "$_PINGO_M"
  _pingo_fmt HELP_PULL;    _pingo_help_line "pingo pull [n|alias]" "$_PINGO_M"
  _pingo_fmt HELP_UPDATE;  _pingo_help_line "pingo update" "$_PINGO_M"
  _pingo_fmt HELP_HELP;    _pingo_help_line "pingo help" "$_PINGO_M"
  _pingo_fmt HELP_VERSION; _pingo_help_line "pingo --version" "$_PINGO_M"
  printf '\n'
  _pingo_fmt HELP_MENU_KEYS
  printf '  %s%s%s\n' "${_C_B}" "$_PINGO_M" "${_C_R}"
  _pingo_help_keys
  printf '\n'
}

_pingo_help_keys() {
  _pingo_fmt KEY_NAV;      _pingo_help_line "↑ ↓  j k  Home End" "$_PINGO_M"
  _pingo_fmt KEY_OPEN;     _pingo_help_line "Enter" "$_PINGO_M"
  _pingo_fmt KEY_JUMP;     _pingo_help_line "1-9" "$_PINGO_M"
  _pingo_fmt KEY_ADD;      _pingo_help_line "a" "$_PINGO_M"
  _pingo_fmt KEY_REMOVE;   _pingo_help_line "d" "$_PINGO_M"
  _pingo_fmt KEY_MOVE;     _pingo_help_line "m" "$_PINGO_M"
  _pingo_fmt KEY_RENAME;   _pingo_help_line "r" "$_PINGO_M"
  _pingo_fmt KEY_SETTINGS; _pingo_help_line "s" "$_PINGO_M"
  _pingo_fmt KEY_HELP;     _pingo_help_line "?" "$_PINGO_M"
  _pingo_fmt KEY_QUIT;     _pingo_help_line "q  Esc" "$_PINGO_M"
}

# --- interactive menu -------------------------------------------------------------

# Read one key -> $_PINGO_K. Optional $1 = timeout in seconds.
_pingo_read1() {
  _PINGO_K=
  if [ -n "${ZSH_VERSION:-}" ]; then
    if [ -t 0 ]; then
      if [ -n "${1:-}" ]; then read -rs -t "$1" -k 1 _PINGO_K; else read -rs -k 1 _PINGO_K; fi
    else
      if [ -n "${1:-}" ]; then read -r -t "$1" -k 1 -u 0 _PINGO_K; else read -r -k 1 -u 0 _PINGO_K; fi
    fi
  else
    if [ -n "${1:-}" ]; then IFS= read -rs -n 1 -t "$1" _PINGO_K; else IFS= read -rs -n 1 _PINGO_K; fi
  fi
}

# Read a key press -> $_PINGO_KEY (up down home end pgup pgdn enter esc bs char)
#                     $_PINGO_C (the character, when KEY=char)
_pingo_readkey() {
  local c
  _PINGO_KEY=
  _PINGO_C=
  if ! _pingo_read1; then
    [ -n "$_PINGO_K" ] || return 1 # EOF or interrupted
  fi
  # bash 3.2 returns 0 from a trap's `return`, so check the Ctrl-C flag too.
  [ "${_PINGO_INT:-0}" -eq 0 ] || return 1
  case "$_PINGO_K" in
    $'\033')
      if _pingo_read1 "$_PINGO_ESC_T"; then
        case "$_PINGO_K" in
          '[' | O)
            _pingo_read1 "$_PINGO_ESC_T"
            case "$_PINGO_K" in
              A) _PINGO_KEY=up ;;
              B) _PINGO_KEY=down ;;
              C) _PINGO_KEY=right ;;
              D) _PINGO_KEY=left ;;
              H) _PINGO_KEY=home ;;
              F) _PINGO_KEY=end ;;
              [0-9])
                c=$_PINGO_K
                _pingo_read1 "$_PINGO_ESC_T" # trailing "~"
                case "$c" in
                  1 | 7) _PINGO_KEY=home ;;
                  4 | 8) _PINGO_KEY=end ;;
                  5) _PINGO_KEY=pgup ;;
                  6) _PINGO_KEY=pgdn ;;
                  *) _PINGO_KEY=other ;;
                esac
                ;;
              *) _PINGO_KEY=other ;;
            esac
            ;;
          *) _PINGO_KEY=esc ;;
        esac
      else
        _PINGO_KEY=esc
      fi
      ;;
    '' | "$_PINGO_NL" | $'\r') _PINGO_KEY=enter ;;
    $'\003' | $'\004') _PINGO_KEY=quit ;; # Ctrl-C / Ctrl-D read as characters
    $'\177' | $'\b') _PINGO_KEY=bs ;;
    *)
      _PINGO_KEY=char
      _PINGO_C=$_PINGO_K
      ;;
  esac
  return 0
}

_pingo_tui_enter() {
  [ -t 1 ] && printf '\033[?1049h\033[?25l\033[H\033[2J'
  return 0
}

_pingo_tui_leave() {
  [ -t 1 ] && printf '\033[?25h\033[?1049l'
  return 0
}

# Read a line of text at the bottom of the screen -> $_PINGO_ANS
_pingo_prompt() {
  _PINGO_ANS=
  printf '  %s?%s %s ' "${_C_YEL}" "${_C_R}" "$1"
  [ -t 1 ] && printf '\033[?25h'
  IFS= read -r _PINGO_ANS || _PINGO_ANS=
  _PINGO_ANS=${_PINGO_ANS%$'\r'}
  [ -t 1 ] && printf '\033[?25l'
  return 0
}

# Footer item: key + label
_pingo_fk() { # key message-key
  _pingo_fmt "$2"
  _PINGO_FOOT="$_PINGO_FOOT${_C_B}$1${_C_R} ${_C_D}$_PINGO_M${_C_R}   "
}

# Uses (dynamic scope) from _pingo_menu: sel off moving msg
_pingo_draw() {
  local lines=${LINES:-24} vis i last out el=$'\033[K' nl=$_PINGO_NL title
  vis=$((lines - 7))
  [ "$vis" -lt 1 ] && vis=1
  [ "$sel" -gt "$_PINGO_N" ] && sel=$_PINGO_N
  [ "$sel" -lt 1 ] && sel=1
  [ "$sel" -le "$off" ] && off=$((sel - 1))
  [ "$sel" -gt $((off + vis)) ] && off=$((sel - vis))
  [ "$off" -lt 0 ] && off=0
  _pingo_layout

  if [ "$_PINGO_N" -eq 1 ]; then _pingo_fmt COUNT_ONE; else _pingo_fmt COUNT_MANY "$_PINGO_N"; fi
  title="  ${_C_B}${_C_CYN}pingo${_C_R}  ${_C_D}· $_PINGO_M${_C_R}"
  if [ "$moving" -eq 1 ]; then
    _pingo_fmt MOVE_MODE
    title="$title  ${_C_YEL}· $_PINGO_M${_C_R}"
  fi
  out=$'\033[H'"$title$el$nl$el$nl"

  if [ "$_PINGO_N" -eq 0 ]; then
    _pingo_fmt EMPTY
    out="$out  $_PINGO_M$el$nl"
    _pingo_fmt EMPTY_MENU_HINT
    out="$out  ${_C_D}$_PINGO_M${_C_R}$el$nl"
  else
    if [ "$off" -gt 0 ]; then
      _pingo_fmt MORE_ABOVE "$off"
      out="$out      ${_C_D}↑ $_PINGO_M${_C_R}$el$nl"
    else
      out="$out$el$nl"
    fi
    i=$((off + 1))
    last=$((off + vis))
    [ "$last" -gt "$_PINGO_N" ] && last=$_PINGO_N
    while [ "$i" -le "$last" ]; do
      if [ "$i" -eq "$sel" ]; then
        if [ "$moving" -eq 1 ]; then _pingo_row "$i" 2; else _pingo_row "$i" 1; fi
      else
        _pingo_row "$i" 0
      fi
      out="$out$_PINGO_ROW$el$nl"
      i=$((i + 1))
    done
    if [ "$last" -lt "$_PINGO_N" ]; then
      _pingo_fmt MORE_BELOW $((_PINGO_N - last))
      out="$out      ${_C_D}↓ $_PINGO_M${_C_R}$el$nl"
    else
      out="$out$el$nl"
    fi
  fi

  _PINGO_FOOT=
  if [ "$moving" -eq 1 ]; then
    _pingo_fk "↑↓" F_MOVE_ITEM
    _pingo_fk "⏎" F_DROP
    _pingo_fk "esc" F_CANCEL
  else
    _pingo_fk "⏎" F_OPEN
    _pingo_fk "a" F_ADD
    _pingo_fk "d" F_REMOVE
    _pingo_fk "m" F_MOVE
    _pingo_fk "s" F_SETTINGS
    _pingo_fk "?" F_HELP
    _pingo_fk "q" F_QUIT
  fi
  out="$out$el$nl  $_PINGO_FOOT$el$nl"
  out="$out  $msg$el$nl"$'\033[J'
  printf '%s' "$out"
}

# Generic single-choice screen. $1 title, $2 items (newline separated),
# $3 initially selected. Result -> $_PINGO_CHOICE (0 = cancelled)
_pingo_choose() {
  local csel=$3 cn=0 rest item i out el=$'\033[K' nl=$_PINGO_NL
  rest=$2
  while [ -n "$rest" ]; do
    rest=${rest#*"$_PINGO_NL"}
    cn=$((cn + 1))
  done
  _PINGO_CHOICE=0
  while :; do
    out=$'\033[H'"  ${_C_B}${_C_CYN}$1${_C_R}$el$nl$el$nl"
    rest=$2
    i=1
    while [ -n "$rest" ]; do
      item=${rest%%"$_PINGO_NL"*}
      rest=${rest#*"$_PINGO_NL"}
      if [ "$i" -eq "$csel" ]; then
        out="$out  ${_C_CYN}${_C_B}❯ $item${_C_R}$el$nl"
      else
        out="$out    $item$el$nl"
      fi
      i=$((i + 1))
    done
    _PINGO_FOOT=
    _pingo_fk "↑↓" F_NAVIGATE
    _pingo_fk "⏎" F_SELECT
    _pingo_fk "esc" F_BACK
    out="$out$el$nl  $_PINGO_FOOT$el$nl"$'\033[J'
    printf '%s' "$out"
    _pingo_readkey || return 1
    case "$_PINGO_KEY:$_PINGO_C" in
      up:* | char:k) [ "$csel" -gt 1 ] && csel=$((csel - 1)) ;;
      down:* | char:j) [ "$csel" -lt "$cn" ] && csel=$((csel + 1)) ;;
      enter:*)
        _PINGO_CHOICE=$csel
        return 0
        ;;
      esc:* | char:q | left:* | char:h) return 0 ;;
      quit:*) return 1 ;;
    esac
  done
}

_pingo_menu_lang() {
  local rest c items= i=1 cur=1 code
  _pingo_langs
  rest=$_PINGO_LANGS
  while [ -n "$rest" ]; do
    c=${rest%%"$_PINGO_NL"*}
    rest=${rest#*"$_PINGO_NL"}
    _pingo_lang_name "$c"
    _pingo_pad "$c" 8
    if [ "$c" = "$_PINGO_LANG" ]; then
      cur=$i
      items="$items$_PINGO_PAD $_PINGO_LNAME  ●$_PINGO_NL"
    else
      items="$items$_PINGO_PAD $_PINGO_LNAME$_PINGO_NL"
    fi
    i=$((i + 1))
  done
  _pingo_fmt SETTINGS_LANG_TITLE
  _pingo_choose "$_PINGO_M" "$items" "$cur" || return 1
  [ "$_PINGO_CHOICE" -gt 0 ] || return 0
  i=1
  rest=$_PINGO_LANGS
  while [ -n "$rest" ]; do
    code=${rest%%"$_PINGO_NL"*}
    rest=${rest#*"$_PINGO_NL"}
    if [ "$i" -eq "$_PINGO_CHOICE" ]; then
      _pingo_config_set lang "$code"
      _pingo_load_lang
      _pingo_lang_name "$code"
      _pingo_fmt LANG_SET "$_PINGO_LNAME"
      msg="${_C_GRN}✓${_C_R} $_PINGO_M"
      return 0
    fi
    i=$((i + 1))
  done
}

_pingo_menu_settings() {
  local items
  while :; do
    _pingo_lang_name "$_PINGO_LANG"
    _pingo_fmt SETTINGS_LANG
    items="$_PINGO_M: $_PINGO_LNAME$_PINGO_NL"
    _pingo_fmt SETTINGS_TITLE
    _pingo_choose "$_PINGO_M" "$items" 1 || return 1
    case "$_PINGO_CHOICE" in
      0) return 0 ;;
      1) _pingo_menu_lang || return 1 ;;
    esac
  done
}

_pingo_menu_help() {
  local el=$'\033[K'
  _pingo_fmt HELP_MENU_KEYS
  printf '\033[H  %s%s%s%s\n%s\n' "${_C_B}" "${_C_CYN}" "$_PINGO_M" "$el" "$el"
  _pingo_help_keys
  _pingo_fmt PRESS_ANY_KEY
  printf '%s\n  %s%s%s%s\n\033[J' "$el" "${_C_D}" "$_PINGO_M" "${_C_R}" "$el"
  _pingo_readkey || return 1
  return 0
}

_pingo_menu_add() {
  if ! _pingo_check_new_path "$PWD"; then
    msg="${_C_RED}✗${_C_R} $_PINGO_M"
    return 0
  fi
  _pingo_tilde "$PWD"
  _pingo_fmt PROMPT_ALIAS "$_PINGO_TL"
  _pingo_prompt "$_PINGO_M"
  [ "${_PINGO_INT:-0}" -eq 0 ] || return 1
  if _pingo_op_add "$PWD" "$_PINGO_ANS"; then
    sel=$_PINGO_N
    msg="${_C_GRN}✓${_C_R} $_PINGO_M"
    [ -n "$_PINGO_W" ] && msg="$msg  ${_C_YEL}($_PINGO_W)${_C_R}"
  else
    msg="${_C_RED}✗${_C_R} $_PINGO_M"
  fi
}

_pingo_menu_remove() {
  [ "$_PINGO_N" -gt 0 ] || return 0
  _pingo_get "$sel"
  _pingo_fmt CONFIRM_REMOVE "$sel" "${_C_B}$_PINGO_NAME${_C_R}"
  printf '  %s?%s %s ' "${_C_YEL}" "${_C_R}" "$_PINGO_M"
  _pingo_readkey || return 1
  if [ "$_PINGO_KEY" = char ] && _pingo_is_yes "$_PINGO_C"; then
    if _pingo_op_remove "$sel"; then
      msg="${_C_GRN}✓${_C_R} $_PINGO_M"
    else
      msg="${_C_RED}✗${_C_R} $_PINGO_M"
    fi
  else
    _pingo_fmt CANCELLED
    msg="${_C_D}$_PINGO_M${_C_R}"
  fi
  return 0
}

_pingo_menu_rename() {
  [ "$_PINGO_N" -gt 0 ] || return 0
  _pingo_get "$sel"
  _pingo_fmt PROMPT_RENAME "$_PINGO_NAME"
  _pingo_prompt "$_PINGO_M"
  [ "${_PINGO_INT:-0}" -eq 0 ] || return 1
  if [ -z "$_PINGO_ANS" ]; then
    _pingo_fmt CANCELLED
    msg="${_C_D}$_PINGO_M${_C_R}"
  elif _pingo_op_rename "$sel" "$_PINGO_ANS"; then
    msg="${_C_GRN}✓${_C_R} $_PINGO_M"
  else
    msg="${_C_RED}✗${_C_R} $_PINGO_M"
  fi
}

_pingo_menu() {
  local sel=1 off=0 moving=0 msg= digits= target=0 orig= origsel=1 n
  _pingo_load
  _PINGO_INT=0
  # Ctrl-C: zsh re-raises the signal so the prompt comes back as usual; bash
  # returns from the pending `read` (re-raising would kill bash 3.2).
  if [ -n "${ZSH_VERSION:-}" ]; then
    trap '_pingo_tui_leave; trap - INT; kill -INT $$' INT
  else
    trap '_PINGO_INT=1; return 130' INT
  fi
  _pingo_tui_enter
  while :; do
    [ "$_PINGO_INT" -eq 0 ] || break
    _pingo_draw
    msg=
    _pingo_readkey || break

    if [ "$moving" -eq 1 ]; then
      case "$_PINGO_KEY:$_PINGO_C" in
        up:* | char:k)
          if [ "$sel" -gt 1 ]; then
            _pingo_list_move "$sel" $((sel - 1))
            sel=$((sel - 1))
          fi
          ;;
        down:* | char:j)
          if [ "$sel" -lt "$_PINGO_N" ]; then
            _pingo_list_move "$sel" $((sel + 1))
            sel=$((sel + 1))
          fi
          ;;
          quit:*) break ;;
        enter:* | char:m)
          moving=0
          if _pingo_save; then
            _pingo_get "$sel"
            _pingo_fmt MOVED "$_PINGO_NAME" "$sel"
            msg="${_C_GRN}✓${_C_R} $_PINGO_M"
          else
            _pingo_fmt ERR_SAVE "$_PINGO_REPOS"
            msg="${_C_RED}✗${_C_R} $_PINGO_M"
          fi
          ;;
        esc:* | char:q)
          moving=0
          _PINGO_LIST=$orig
          sel=$origsel
          _pingo_fmt CANCELLED
          msg="${_C_D}$_PINGO_M${_C_R}"
          ;;
      esac
      continue
    fi

    case "$_PINGO_KEY" in
      up) if [ "$sel" -gt 1 ]; then sel=$((sel - 1)); else sel=$_PINGO_N; fi ;;
      down) if [ "$sel" -lt "$_PINGO_N" ]; then sel=$((sel + 1)); else sel=1; fi ;;
      home) sel=1 ;;
      end) sel=$_PINGO_N ;;
      pgup) sel=$((sel - 10)) ;;
      pgdn) sel=$((sel + 10)) ;;
      enter)
        if [ "$_PINGO_N" -gt 0 ]; then
          target=$sel
          break
        fi
        ;;
      esc | quit) break ;;
      char)
        case "$_PINGO_C" in
          [0-9])
            n="$digits$_PINGO_C"
            _pingo_number "$n"
            if [ -n "$_PINGO_NUM" ] && [ "$_PINGO_NUM" -ge 1 ] && [ "$_PINGO_NUM" -le "$_PINGO_N" ]; then
              digits=$n
              sel=$_PINGO_NUM
            elif [ "$_PINGO_C" -ge 1 ] && [ "$_PINGO_C" -le "$_PINGO_N" ]; then
              digits=$_PINGO_C
              sel=$_PINGO_C
            else
              digits=
            fi
            continue
            ;;
          j) [ "$sel" -lt "$_PINGO_N" ] && sel=$((sel + 1)) ;;
          k) [ "$sel" -gt 1 ] && sel=$((sel - 1)) ;;
          g) sel=1 ;;
          G) sel=$_PINGO_N ;;
          q | Q) break ;;
          a | A) _pingo_menu_add || break ;;
          d | D | x) _pingo_menu_remove || break ;;
          r | R) _pingo_menu_rename || break ;;
          m | M)
            if [ "$_PINGO_N" -gt 1 ]; then
              moving=1
              orig=$_PINGO_LIST
              origsel=$sel
            fi
            ;;
          s | S) _pingo_menu_settings || break ;;
          '?' | h | H) _pingo_menu_help || break ;;
        esac
        ;;
    esac
    digits=
  done
  if [ "$moving" -eq 1 ]; then
    _PINGO_LIST=$orig
  fi
  _pingo_tui_leave
  trap - INT
  if [ "$_PINGO_INT" -eq 1 ]; then
    _PINGO_INT=0
    return 130
  fi
  if [ "$target" -gt 0 ]; then
    _pingo_go "$target"
    return $?
  fi
  return 0
}

# --- entry point --------------------------------------------------------------------

pingo() {
  if [ -n "${ZSH_VERSION:-}" ]; then
    setopt localoptions localtraps nonomatch noksharrays noshwordsplit 2>/dev/null
  fi
  _pingo_init
  case "${1:-}" in
    '') _pingo_menu ;;
    ls | list) _pingo_cmd_ls ;;
    add) shift; _pingo_cmd_add "$@" ;;
    rm | remove) shift; _pingo_cmd_rm "$@" ;;
    mv | move) shift; _pingo_cmd_mv "$@" ;;
    rename) shift; _pingo_cmd_rename "$@" ;;
    prune) _pingo_cmd_prune ;;
    config) shift; _pingo_cmd_config "$@" ;;
    update) _pingo_cmd_update ;;
    pull) shift; _pingo_cmd_pull "$@" ;;
    help | -h | --help) _pingo_cmd_help ;;
    version | -v | -V | --version) printf 'pingo %s\n' "$PINGO_VERSION" ;;
    -*)
      _pingo_fmt ERR_UNKNOWN_OPTION "$1"
      _pingo_fail "$_PINGO_M"
      return 2
      ;;
    *) _pingo_cmd_go "$1" ;;
  esac
}

# Words offered by tab completion, one per line.
_pingo_completion_words() {
  local i=1
  _pingo_init
  _pingo_load
  printf '%s\n' ls add rm mv rename prune config update pull help
  while [ "$i" -le "$_PINGO_N" ]; do
    _pingo_get "$i"
    printf '%s\n' "$_PINGO_NAME"
    i=$((i + 1))
  done
}

_pingo_completion_names() {
  local i=1
  _pingo_init
  _pingo_load
  while [ "$i" -le "$_PINGO_N" ]; do
    _pingo_get "$i"
    printf '%s\n' "$_PINGO_NAME"
    i=$((i + 1))
  done
}

# --- tab completion -----------------------------------------------------------------
if [ -n "${ZSH_VERSION:-}" ]; then
  [ -f "$PINGO_HOME/completion/pingo.zsh" ] && . "$PINGO_HOME/completion/pingo.zsh"
elif [ -n "${BASH_VERSION:-}" ]; then
  [ -f "$PINGO_HOME/completion/pingo.bash" ] && . "$PINGO_HOME/completion/pingo.bash"
fi
