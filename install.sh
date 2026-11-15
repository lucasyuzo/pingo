#!/usr/bin/env bash
# pingo installer — adds one line to your shell startup file that loads pingo.
#
#   ./install.sh                                 interactive
#   ./install.sh --rc ~/.zshrc --lang pt-BR -y   non-interactive
#
# Options:
#   --rc <file>     startup file to load pingo from (~/.zshrc, ~/.bash_profile, ~/.bashrc...)
#   --lang <code>   interface language (default: detected from your system)
#   -y, --yes       don't ask questions, use the defaults
#   -h, --help      show this help

set -u

case "$0" in
  */*) _dir=${0%/*} ;;
  *) _dir=. ;;
esac
PINGO_SRC_DIR=$(CDPATH= cd -- "$_dir" && pwd) || exit 1

opt_rc=
opt_lang=
opt_yes=0
while [ $# -gt 0 ]; do
  case "$1" in
    --rc) opt_rc=${2:-}; shift ;;
    --rc=*) opt_rc=${1#--rc=} ;;
    --lang) opt_lang=${2:-}; shift ;;
    --lang=*) opt_lang=${1#--lang=} ;;
    -y | --yes) opt_yes=1 ;;
    -h | --help)
      while IFS= read -r line; do
        case "$line" in
          '#!'*) ;;
          '#'*) line=${line#\#}; printf '%s\n' "${line# }" ;;
          *) break ;;
        esac
      done <"$0"
      exit 0
      ;;
    *)
      printf 'Unknown option: %s (see --help)\n' "$1" >&2
      exit 2
      ;;
  esac
  shift
done
[ -t 0 ] || [ -n "${PINGO_INSTALL_INTERACTIVE:-}" ] || opt_yes=1

# shellcheck source=pingo.sh
. "$PINGO_SRC_DIR/pingo.sh"
_pingo_init

MARK="  # pingo"
MARK_BASHRC="  # pingo (loads ~/.bashrc)"
MARK_PROFILE="  # pingo (loads ~/.profile)"

# --- helpers --------------------------------------------------------------------

# "$HOME/x" style path for the startup line, so it survives a moved home.
home_relative() {
  case "$1" in
    "$HOME") printf '%s' '$HOME' ;;
    "$HOME"/*) printf '%s' "\$HOME${1#"$HOME"}" ;;
    *) printf '%s' "$1" ;;
  esac
}

expand_tilde() {
  case "$1" in
    "~") printf '%s' "$HOME" ;;
    "~/"*) printf '%s' "$HOME/${1#??}" ;;
    *) printf '%s' "$1" ;;
  esac
}

# file_has_line FILE LINE
file_has_line() {
  local l=
  [ -f "$1" ] || return 1
  while IFS= read -r l || [ -n "$l" ]; do
    [ "${l%$'\r'}" = "$2" ] && return 0
  done <"$1"
  return 1
}

# Does FILE contain a pingo line (any version)?
file_has_mark() {
  local l=
  [ -f "$1" ] || return 1
  while IFS= read -r l || [ -n "$l" ]; do
    case "${l%$'\r'}" in *"$MARK") return 0 ;; esac
  done <"$1"
  return 1
}

# Does FILE already load ~/.bashrc (outside comments)?
file_loads_bashrc() {
  local l= t
  [ -f "$1" ] || return 1
  while IFS= read -r l || [ -n "$l" ]; do
    t=${l#"${l%%[![:space:]]*}"}
    case "$t" in
      '#'*) ;;
      *bashrc*) return 0 ;;
    esac
  done <"$1"
  return 1
}

# Remove lines ending with $MARK (exactly) from FILE.
remove_pingo_line() {
  local l= out= nl=$_PINGO_NL
  [ -f "$1" ] || return 0
  while IFS= read -r l || [ -n "$l" ]; do
    case "${l%$'\r'}" in *"$MARK") continue ;; esac
    out="$out$l$nl"
  done <"$1"
  printf '%s' "$out" >"$1"
}

# Append LINE to FILE, making sure the file ends with a newline first.
append_line() {
  local l=
  if [ -s "$1" ]; then
    while IFS= read -r l; do :; done <"$1"
    [ -n "$l" ] && printf '\n' >>"$1"
  fi
  printf '%s\n' "$2" >>"$1"
}

# --- language ---------------------------------------------------------------------

if [ -n "$opt_lang" ]; then
  if ! _pingo_lang_file "$opt_lang"; then
    _pingo_fmt ERR_UNKNOWN_LANG "$opt_lang"
    _pingo_fail "$_PINGO_M"
    exit 1
  fi
  lang=$opt_lang
elif _pingo_config_get lang && [ -n "$_PINGO_VAL" ] && _pingo_lang_file "$_PINGO_VAL"; then
  lang=$_PINGO_VAL
else
  _pingo_detect_lang
  lang=$_PINGO_DETECTED
fi
if ! _pingo_config_set lang "$lang"; then
  _pingo_fmt ERR_SAVE "$_PINGO_CONFIG"
  _pingo_fail "$_PINGO_M"
  exit 1
fi
_pingo_load_lang

_pingo_fmt INSTALL_TITLE
printf '\n  %s%s🐾 %s%s  %sv%s%s\n\n' "${_C_B}" "${_C_CYN}" "$_PINGO_M" "${_C_R}" "${_C_D}" "$PINGO_VERSION" "${_C_R}"
_pingo_lang_name "$lang"
_pingo_fmt INSTALL_LANG "$_PINGO_LNAME"
_pingo_info "$_PINGO_M"

# --- startup file -----------------------------------------------------------------

shell_name=${SHELL##*/}
if [ "$shell_name" = zsh ]; then
  default=1
elif _pingo_is_windows || case "${OSTYPE:-}" in darwin*) true ;; *) false ;; esac; then
  default=2
else
  default=3
fi

if [ -n "$opt_rc" ]; then
  rc=$(expand_tilde "$opt_rc")
elif [ "$opt_yes" -eq 1 ]; then
  case "$default" in 1) rc="$HOME/.zshrc" ;; 2) rc="$HOME/.bash_profile" ;; *) rc="$HOME/.bashrc" ;; esac
else
  _pingo_fmt INSTALL_RC_QUESTION
  printf '\n  %s%s%s\n' "${_C_B}" "$_PINGO_M" "${_C_R}"
  _pingo_fmt INSTALL_RECOMMENDED
  i=1
  for f in .zshrc .bash_profile .bashrc; do
    if [ "$i" -eq "$default" ]; then
      printf '    %s%s)%s ~/%s  %s(%s)%s\n' "${_C_CYN}" "$i" "${_C_R}" "$f" "${_C_GRN}" "$_PINGO_M" "${_C_R}"
    else
      printf '    %s%s)%s ~/%s\n' "${_C_CYN}" "$i" "${_C_R}" "$f"
    fi
    i=$((i + 1))
  done
  while :; do
    _pingo_fmt INSTALL_CHOICE "$default"
    printf '  %s ' "$_PINGO_M"
    IFS= read -r choice || choice=
    choice=${choice%$'\r'}
    [ -n "$choice" ] || choice=$default
    case "$choice" in
      1) rc="$HOME/.zshrc"; break ;;
      2) rc="$HOME/.bash_profile"; break ;;
      3) rc="$HOME/.bashrc"; break ;;
      *)
        _pingo_fmt INSTALL_INVALID "$choice"
        _pingo_fail "$_PINGO_M"
        ;;
    esac
  done
  printf '\n'
fi

src=$(home_relative "$PINGO_SRC_DIR/pingo.sh")
line="[ -f \"$src\" ] && . \"$src\"$MARK"

_pingo_tilde "$rc"
rc_disp=$_PINGO_TL
if file_has_line "$rc" "$line"; then
  _pingo_fmt INSTALL_ALREADY "$rc_disp"
  _pingo_ok "$_PINGO_M"
else
  file_has_mark "$rc" && remove_pingo_line "$rc"
  if ! append_line "$rc" "$line"; then
    _pingo_fmt ERR_SAVE "$rc_disp"
    _pingo_fail "$_PINGO_M"
    exit 1
  fi
  _pingo_fmt INSTALL_ADDED "$rc_disp"
  _pingo_ok "$_PINGO_M"
fi

# Login shells (Git Bash, macOS Terminal) read ~/.bash_profile, not ~/.bashrc.
if [ "$rc" = "$HOME/.bashrc" ]; then
  bp="$HOME/.bash_profile"
  if ! file_loads_bashrc "$bp"; then
    if [ ! -f "$bp" ] && [ -f "$HOME/.profile" ]; then
      # Creating ~/.bash_profile would stop bash from reading ~/.profile.
      append_line "$bp" '[ -f "$HOME/.profile" ] && . "$HOME/.profile"'"$MARK_PROFILE"
    fi
    if ! file_loads_bashrc "$bp" && ! { file_has_line "$bp" '[ -f "$HOME/.profile" ] && . "$HOME/.profile"'"$MARK_PROFILE" && file_loads_bashrc "$HOME/.profile"; }; then
      append_line "$bp" '[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"'"$MARK_BASHRC"
    fi
    _pingo_fmt INSTALL_BASH_PROFILE "~/.bash_profile"
    _pingo_ok "$_PINGO_M"
  fi
fi

_pingo_fmt INSTALL_DONE
printf '\n  %s%s%s\n' "${_C_GRN}${_C_B}" "$_PINGO_M" "${_C_R}"
_pingo_fmt INSTALL_NEXT "$rc_disp"
printf '  %s\n' "$_PINGO_M"
_pingo_fmt INSTALL_TRY
printf '  %s%s%s\n\n' "${_C_D}" "$_PINGO_M" "${_C_R}"
