# Core commands: add, ls, go, rm, mv, rename, prune, validations.
T_DIR=${T_DIR:-${0%/*}}
. "$T_DIR/lib.sh"

t_repo "$T_TMP/work/api"
t_repo "$T_TMP/work/web" "feat/login"
mkdir -p "$T_TMP/work/notes" "$T_TMP/other/api"

# --- add ---
out=$(pingo add "$T_TMP/work/api" 2>&1); st=$?
assert_status $st 0 "add without alias succeeds"
assert_contains "$out" "Added #1 api" "add reports position and name"

out=$(pingo add "$T_TMP/work/web" front 2>&1)
assert_contains "$out" "Added #2 front" "add with alias"

out=$(pingo add "$T_TMP/work/notes" 2>&1); st=$?
assert_status $st 0 "non-git directory is accepted"
assert_contains "$out" "not a git repository" "non-git directory warns"

out=$(pingo add "$T_TMP/work/api" again 2>&1); st=$?
assert_status $st 1 "duplicate path is rejected"
assert_contains "$out" "already registered as #1" "duplicate path message"

out=$(pingo add "$T_TMP/work/api/" 2>&1); st=$?
assert_status $st 1 "duplicate path with trailing slash is rejected"

out=$(pingo add "$T_TMP/nope" 2>&1); st=$?
assert_status $st 1 "missing directory is rejected"
assert_contains "$out" "Not a directory" "missing directory message"

out=$(pingo add 2>&1); st=$?
assert_status $st 2 "add without arguments shows usage"

# --- alias validation ---
for bad in 123 "has space" "a|b" "-x" ls add config front; do
  out=$(pingo add "$T_TMP/other/api" "$bad" 2>&1); st=$?
  assert_status $st 1 "alias [$bad] is rejected"
done
out=$(pingo add "$T_TMP/other/api" 123 2>&1)
assert_contains "$out" "numbers are reserved" "numeric alias message"
out=$(pingo add "$T_TMP/other/api" front 2>&1)
assert_contains "$out" "already used by #2" "taken alias message"
out=$(pingo add "$T_TMP/other/api" api 2>&1)
assert_contains "$out" "already used by #1" "alias equal to a folder name is rejected"

# --- relative path ---
cd "$T_TMP/other" || exit 1
out=$(pingo add api api2 2>&1); st=$?
assert_status $st 0 "relative path is accepted"
assert_contains "$(cat "$XDG_CONFIG_HOME/pingo/repos")" "api2|$T_TMP/other/api" "relative path stored as absolute"
cd "$T_TMP" || exit 1

# --- storage format ---
expected="|$T_TMP/work/api
front|$T_TMP/work/web
|$T_TMP/work/notes
api2|$T_TMP/other/api"
assert_eq "$(cat "$XDG_CONFIG_HOME/pingo/repos")" "$expected" "repos file format"

# --- ls ---
out=$(pingo ls)
assert_contains "$out" "1  api" "ls shows first entry"
assert_contains "$out" "front" "ls shows alias"
assert_contains "$out" "⎇ feat/login" "ls shows branch"
line_count=$(pingo ls | wc -l | tr -d ' ')
assert_eq "$line_count" "4" "ls prints one line per repository"

# --- go ---
pingo 2 >/dev/null
assert_eq "$PWD" "$T_TMP/work/web" "go by number"
pingo api >/dev/null
assert_eq "$PWD" "$T_TMP/work/api" "go by folder name"
pingo front >/dev/null
assert_eq "$PWD" "$T_TMP/work/web" "go by alias"
pingo 03 >/dev/null
assert_eq "$PWD" "$T_TMP/work/notes" "go by number with leading zero"
out=$(pingo 9 2>&1); st=$?
assert_status $st 1 "unknown position fails"
assert_contains "$out" "no position 9" "unknown position message"
out=$(pingo nothing 2>&1); st=$?
assert_status $st 1 "unknown name fails"
out=$(pingo --bogus 2>&1); st=$?
assert_status $st 2 "unknown option fails"
cd "$T_TMP" || exit 1

# --- mv ---
out=$(pingo mv 4 1 2>&1); st=$?
assert_status $st 0 "mv succeeds"
assert_contains "$out" "Moved api2 to position 1" "mv message"
first=$(head -n 1 "$XDG_CONFIG_HOME/pingo/repos")
assert_eq "$first" "api2|$T_TMP/other/api" "mv reorders the file"
pingo mv api2 4 >/dev/null
last=$(tail -n 1 "$XDG_CONFIG_HOME/pingo/repos")
assert_eq "$last" "api2|$T_TMP/other/api" "mv by alias to the end"
out=$(pingo mv 1 7 2>&1); st=$?
assert_status $st 1 "mv to invalid position fails"

# --- rename ---
out=$(pingo rename 3 docs 2>&1); st=$?
assert_status $st 0 "rename succeeds"
assert_contains "$out" "Renamed notes to docs" "rename message"
out=$(pingo rename docs front 2>&1); st=$?
assert_status $st 1 "rename to a taken alias fails"
out=$(pingo rename docs docs 2>&1); st=$?
assert_status $st 0 "rename to its own alias is allowed"

# --- rm ---
out=$(printf 'n\n' | pingo rm docs 2>&1); st=$?
assert_status $st 1 "rm cancelled when not confirmed"
assert_contains "$(cat "$XDG_CONFIG_HOME/pingo/repos")" "docs|" "cancelled rm keeps entry"
out=$(printf 'y\n' | pingo rm docs 2>&1); st=$?
assert_status $st 0 "rm confirmed with y"
assert_not_contains "$(cat "$XDG_CONFIG_HOME/pingo/repos")" "docs|" "rm removes entry"
out=$(pingo rm api2 -y 2>&1); st=$?
assert_status $st 0 "rm -y removes without asking"

# --- ambiguous folder names ---
t_reset
mkdir -p "$T_TMP/a/app" "$T_TMP/b/app"
pingo add "$T_TMP/a/app" >/dev/null 2>&1
pingo add "$T_TMP/b/app" >/dev/null 2>&1
out=$(pingo app 2>&1); st=$?
assert_status $st 1 "ambiguous folder name fails"
assert_contains "$out" "More than one" "ambiguous message"

# --- prune ---
rm -rf "$T_TMP/a/app"
out=$(pingo ls)
assert_contains "$out" "✗ not found" "missing repository is flagged"
out=$(pingo 1 2>&1); st=$?
assert_status $st 1 "going to a missing repository fails"
assert_contains "$out" "pingo prune" "missing repository suggests prune"
out=$(pingo prune 2>&1)
assert_contains "$out" "Pruned 1" "prune removes missing entries"
assert_eq "$(cat "$XDG_CONFIG_HOME/pingo/repos")" "|$T_TMP/b/app" "prune keeps existing entries"
out=$(pingo prune 2>&1)
assert_contains "$out" "Nothing to prune" "prune with nothing to do"

# --- tolerant file reading (CRLF, bare paths, blank lines) ---
t_reset
mkdir -p "$XDG_CONFIG_HOME/pingo" "$T_TMP/x" "$T_TMP/y"
printf 'xx|%s\r\n\r\n%s' "$T_TMP/x" "$T_TMP/y" >"$XDG_CONFIG_HOME/pingo/repos"
pingo xx >/dev/null
assert_eq "$PWD" "$T_TMP/x" "CRLF line is understood"
pingo y >/dev/null
assert_eq "$PWD" "$T_TMP/y" "bare path line without trailing newline is understood"

# --- empty list ---
t_reset
out=$(pingo ls)
assert_contains "$out" "No repositories yet" "empty list hint"

# --- help & version ---
assert_contains "$(pingo help)" "pingo add <path> [alias]" "help lists commands"
assert_eq "$(pingo --version)" "pingo $PINGO_VERSION" "version"

t_done
