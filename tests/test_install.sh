# install.sh / uninstall.sh in an isolated HOME.
T_DIR=${T_DIR:-${0%/*}}
. "$T_DIR/lib.sh"

count_lines() { # file pattern
  local n=0 l
  [ -f "$1" ] || { echo 0; return; }
  while IFS= read -r l || [ -n "$l" ]; do
    case "$l" in *"$2"*) n=$((n + 1)) ;; esac
  done <"$1"
  echo "$n"
}

# --- zsh: non-interactive ---
printf 'export FOO=1' >"$HOME/.zshrc" # no trailing newline on purpose
out=$(bash "$T_ROOT/install.sh" --rc "$HOME/.zshrc" --lang pt-BR --yes 2>&1); st=$?
assert_status $st 0 "install succeeds"
assert_contains "$out" "pingo instalado" "installer speaks the chosen language"
assert_eq "$(count_lines "$HOME/.zshrc" '# pingo')" "1" "one pingo line in .zshrc"
assert_eq "$(head -n 1 "$HOME/.zshrc")" "export FOO=1" "existing content is preserved"
assert_contains "$(cat "$XDG_CONFIG_HOME/pingo/config")" "lang=pt-BR" "config created with language"

bash "$T_ROOT/install.sh" --rc "~/.zshrc" --yes >/dev/null 2>&1
assert_eq "$(count_lines "$HOME/.zshrc" '# pingo')" "1" "reinstall does not duplicate the line"
assert_contains "$(cat "$XDG_CONFIG_HOME/pingo/config")" "lang=pt-BR" "reinstall keeps the language"

# The line really loads pingo.
if command -v zsh >/dev/null 2>&1; then
  out=$(zsh -c ". \"$HOME/.zshrc\"; pingo --version" 2>&1)
  assert_eq "$out" "pingo $PINGO_VERSION" "zsh loads pingo from .zshrc"
fi

# --- bash: .bashrc + .bash_profile loader ---
printf 'alias ll="ls -l"\n' >"$HOME/.bashrc"
bash "$T_ROOT/install.sh" --rc "$HOME/.bashrc" --yes >/dev/null 2>&1
assert_eq "$(count_lines "$HOME/.bashrc" '# pingo')" "1" "pingo line in .bashrc"
assert_eq "$(count_lines "$HOME/.bash_profile" '# pingo (loads ~/.bashrc)')" "1" ".bash_profile loads .bashrc"
bash "$T_ROOT/install.sh" --rc "$HOME/.bashrc" --yes >/dev/null 2>&1
assert_eq "$(count_lines "$HOME/.bash_profile" '.bashrc')" "1" "loader is not duplicated"
out=$(HOME="$HOME" bash --login -c 'pingo --version' 2>&1)
assert_eq "$out" "pingo $PINGO_VERSION" "bash login shell loads pingo"

# Existing .bash_profile that already loads .bashrc is left alone.
printf 'if [ -f ~/.bashrc ]; then . ~/.bashrc; fi\n' >"$HOME/.bash_profile"
bash "$T_ROOT/install.sh" --rc "$HOME/.bashrc" --yes >/dev/null 2>&1
assert_eq "$(cat "$HOME/.bash_profile")" "if [ -f ~/.bashrc ]; then . ~/.bashrc; fi" ".bash_profile untouched when it already loads .bashrc"

# No .bash_profile but a .profile that loads .bashrc (Debian/Ubuntu style).
rm -f "$HOME/.bash_profile"
printf 'if [ -n "$BASH_VERSION" ]; then . "$HOME/.bashrc"; fi\n' >"$HOME/.profile"
bash "$T_ROOT/install.sh" --rc "$HOME/.bashrc" --yes >/dev/null 2>&1
assert_eq "$(count_lines "$HOME/.bash_profile" '.profile')" "1" ".bash_profile keeps loading .profile"
assert_eq "$(count_lines "$HOME/.bash_profile" '.bashrc')" "0" "no double load when .profile already loads .bashrc"

# --- bash_profile chosen directly ---
bash "$T_ROOT/install.sh" --rc "$HOME/.bash_profile" --yes >/dev/null 2>&1
assert_eq "$(count_lines "$HOME/.bash_profile" '  # pingo')" "2" ".bash_profile has the pingo line"

# --- invalid language ---
out=$(bash "$T_ROOT/install.sh" --rc "$HOME/.zshrc" --lang xx --yes 2>&1); st=$?
assert_status $st 1 "unknown --lang is rejected"

# --- interactive choice ---
rm -f "$HOME/.zshrc"
out=$(printf '9\n1\n' | PINGO_INSTALL_INTERACTIVE=1 SHELL=/bin/zsh bash "$T_ROOT/install.sh" --lang en 2>&1)
assert_contains "$out" "Invalid choice: 9" "invalid choice is reported"
assert_eq "$(count_lines "$HOME/.zshrc" '# pingo')" "1" "interactive choice 1 writes .zshrc"

# --- uninstall ---
pingo add "$T_TMP" >/dev/null 2>&1
out=$(bash "$T_ROOT/uninstall.sh" --yes 2>&1); st=$?
assert_status $st 0 "uninstall succeeds"
assert_eq "$(count_lines "$HOME/.zshrc" 'pingo')" "0" "uninstall cleans .zshrc"
assert_eq "$(count_lines "$HOME/.bashrc" 'pingo')" "0" "uninstall cleans .bashrc"
assert_eq "$(cat "$HOME/.bashrc")" 'alias ll="ls -l"' "uninstall keeps user content"
assert_eq "$([ -f "$HOME/.bash_profile" ] && echo yes || echo no)" "no" "empty .bash_profile created by pingo is deleted"
assert_eq "$([ -d "$XDG_CONFIG_HOME/pingo" ] && echo yes || echo no)" "yes" "--yes keeps user data"

bash "$T_ROOT/install.sh" --rc "$HOME/.zshrc" --yes >/dev/null 2>&1
bash "$T_ROOT/uninstall.sh" --purge >/dev/null 2>&1
assert_eq "$([ -d "$XDG_CONFIG_HOME/pingo" ] && echo yes || echo no)" "no" "--purge deletes user data"

t_done
