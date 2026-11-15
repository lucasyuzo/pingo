#!/usr/bin/env bash
# pingo uninstaller — removes the lines added by install.sh.
#
#   ./uninstall.sh            interactive (asks whether to delete your data)
#   ./uninstall.sh --yes      no questions; keeps your repository list
#   ./uninstall.sh --purge    no questions; also deletes your repository list and settings

set -u

case "$0" in
  */*) _dir=${0%/*} ;;
  *) _dir=. ;;
esac
PINGO_SRC_DIR=$(CDPATH= cd -- "$_dir" && pwd) || exit 1

opt_yes=0
opt_purge=0
while [ $# -gt 0 ]; do
  case "$1" in
    -y | --yes) opt_yes=1 ;;
    --purge) opt_yes=1; opt_purge=1 ;;
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
[ -t 0 ] || opt_yes=1

# shellcheck source=pingo.sh
. "$PINGO_SRC_DIR/pingo.sh"
_pingo_init

# Remove every line added by install.sh. Returns 0 if something was removed.
# Deletes the file when nothing else is left in it (a ~/.bash_profile created
# by the installer would otherwise keep bash from reading ~/.profile).
strip_file() {
  local l= out= found=0 rest
  [ -f "$1" ] || return 1
  while IFS= read -r l || [ -n "$l" ]; do
    case "${l%$'\r'}" in
      *"  # pingo" | *"  # pingo (loads ~/.bashrc)" | *"  # pingo (loads ~/.profile)")
        found=1
        continue
        ;;
    esac
    out="$out$l$_PINGO_NL"
  done <"$1"
  [ "$found" -eq 1 ] || return 1
  rest=${out//[[:space:]]/}
  if [ -z "$rest" ]; then
    rm -f "$1"
  else
    printf '%s' "$out" >"$1"
  fi
  return 0
}

_pingo_fmt UNINSTALL_TITLE
printf '\n  %s%s%s%s\n\n' "${_C_B}" "${_C_CYN}" "$_PINGO_M" "${_C_R}"

removed=0
for f in "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile"; do
  if strip_file "$f"; then
    _pingo_tilde "$f"
    _pingo_fmt UNINSTALL_REMOVED "$_PINGO_TL"
    _pingo_ok "$_PINGO_M"
    removed=1
  fi
done
if [ "$removed" -eq 0 ]; then
  _pingo_fmt UNINSTALL_NOTHING
  _pingo_info "$_PINGO_M"
fi

_pingo_tilde "$_PINGO_DATA"
data_disp=$_PINGO_TL
delete=0
if [ "$opt_purge" -eq 1 ]; then
  delete=1
elif [ "$opt_yes" -eq 0 ] && [ -d "$_PINGO_DATA" ]; then
  _pingo_fmt UNINSTALL_ASK_DATA "$data_disp"
  printf '%s?%s %s ' "${_C_YEL}" "${_C_R}" "$_PINGO_M"
  IFS= read -r ans || ans=
  _pingo_is_yes "${ans%$'\r'}" && delete=1
fi

if [ -d "$_PINGO_DATA" ]; then
  if [ "$delete" -eq 1 ]; then
    case "$_PINGO_DATA" in
      */pingo) rm -rf "$_PINGO_DATA" ;;
      *) rm -f "$_PINGO_REPOS" "$_PINGO_CONFIG" ;;
    esac
    _pingo_fmt UNINSTALL_DATA_REMOVED "$data_disp"
    _pingo_ok "$_PINGO_M"
  else
    _pingo_fmt UNINSTALL_DATA_KEPT "$data_disp"
    _pingo_info "$_PINGO_M"
  fi
fi

_pingo_fmt UNINSTALL_DONE
printf '\n  %s%s%s\n' "${_C_GRN}${_C_B}" "$_PINGO_M" "${_C_R}"
_pingo_tilde "$PINGO_SRC_DIR"
_pingo_fmt UNINSTALL_CODE_HINT "$_PINGO_TL"
printf '  %s%s%s\n\n' "${_C_D}" "$_PINGO_M" "${_C_R}"
