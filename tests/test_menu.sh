# Interactive menu, driven by key presses read from a file.
T_DIR=${T_DIR:-${0%/*}}
. "$T_DIR/lib.sh"

KEYS="$T_TMP/keys"
DOWN=$(printf '\033[B')
UP=$(printf '\033[A')
ESC=$(printf '\033')

setup() {
  t_reset
  t_repo "$T_TMP/r/one"
  t_repo "$T_TMP/r/two"
  t_repo "$T_TMP/r/three"
  pingo add "$T_TMP/r/one" >/dev/null 2>&1
  pingo add "$T_TMP/r/two" >/dev/null 2>&1
  pingo add "$T_TMP/r/three" >/dev/null 2>&1
}

menu() { # keys...
  printf '%s' "$@" >"$KEYS"
  pingo <"$KEYS" >"$T_TMP/out" 2>&1
}

repos() { cat "$XDG_CONFIG_HOME/pingo/repos"; }

setup
menu "$DOWN" "
"
assert_eq "$PWD" "$T_TMP/r/two" "arrow down + Enter goes to the 2nd repository"

cd "$T_TMP" || exit 1
menu "j" "j" "k" "
"
assert_eq "$PWD" "$T_TMP/r/two" "j/k navigation"

cd "$T_TMP" || exit 1
menu "$UP" "
"
assert_eq "$PWD" "$T_TMP/r/three" "arrow up wraps to the last entry"

cd "$T_TMP" || exit 1
menu "3" "
"
assert_eq "$PWD" "$T_TMP/r/three" "digit jumps to position"

cd "$T_TMP" || exit 1
menu "q"
assert_eq "$PWD" "$T_TMP" "q quits without changing directory"
menu "$ESC"
assert_eq "$PWD" "$T_TMP" "Esc quits without changing directory"
menu ""
assert_eq "$PWD" "$T_TMP" "end of input quits cleanly"

# --- move mode ---
menu "m" "$DOWN" "$DOWN" "
" "q"
assert_eq "$(repos)" "|$T_TMP/r/two
|$T_TMP/r/three
|$T_TMP/r/one" "m + ↓↓ + Enter moves the first entry to the end"

menu "m" "$DOWN" "$ESC" "q"
assert_eq "$(repos)" "|$T_TMP/r/two
|$T_TMP/r/three
|$T_TMP/r/one" "Esc cancels a move"

menu "m" "$DOWN"
assert_eq "$(repos)" "|$T_TMP/r/two
|$T_TMP/r/three
|$T_TMP/r/one" "quitting in the middle of a move does not save it"

# --- remove ---
setup
menu "$DOWN" "d" "n" "q"
assert_contains "$(repos)" "r/two" "d + n keeps the entry"
menu "$DOWN" "d" "y" "q"
assert_not_contains "$(repos)" "r/two" "d + y removes the entry"
menu "d" "s" "q"
assert_not_contains "$(repos)" "r/one" "d + s (sim) removes the entry"

# --- add current directory ---
setup
t_repo "$T_TMP/r/four"
cd "$T_TMP/r/four" || exit 1
menu "a" "quatro
" "q"
assert_contains "$(repos)" "quatro|$T_TMP/r/four" "a adds the current directory with an alias"
menu "a" "q"
assert_contains "$(cat "$T_TMP/out")" "already registered" "a on a registered directory shows an error"
cd "$T_TMP" || exit 1

# --- rename ---
menu "r" "primeiro
" "q"
assert_contains "$(repos)" "primeiro|$T_TMP/r/one" "r renames the selected entry"

# --- settings: change language ---
menu "s" "
" "$DOWN" "
" "$ESC" "q"
assert_contains "$(cat "$XDG_CONFIG_HOME/pingo/config")" "lang=pt-BR" "settings screen changes the language"
menu "?" "x" "q"
assert_contains "$(cat "$T_TMP/out")" "Teclas do menu" "help screen uses the selected language"

# --- empty list ---
t_reset
menu "
" "q"
assert_eq "$PWD" "$T_TMP" "Enter on an empty list does nothing"
assert_contains "$(cat "$T_TMP/out")" "No repositories yet" "empty menu shows a hint"

t_done
