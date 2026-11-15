# Languages: detection, switching, custom files and fallback.
T_DIR=${T_DIR:-${0%/*}}
. "$T_DIR/lib.sh"

LANG=pt_BR.UTF-8 _pingo_detect_lang; assert_eq "$_PINGO_DETECTED" "pt-BR" "detects pt_BR"
LANG=pt_PT.UTF-8 _pingo_detect_lang; assert_eq "$_PINGO_DETECTED" "pt-BR" "detects pt_PT as pt-BR"
LANG=en_US.UTF-8 _pingo_detect_lang; assert_eq "$_PINGO_DETECTED" "en" "detects en"
LANG=de_DE.UTF-8 _pingo_detect_lang; assert_eq "$_PINGO_DETECTED" "en" "unknown languages fall back to en"
LC_ALL=pt_BR.UTF-8 LANG=en_US.UTF-8 _pingo_detect_lang; assert_eq "$_PINGO_DETECTED" "pt-BR" "LC_ALL wins over LANG"

# Without config, the language follows the environment.
out=$(LANG=pt_BR.UTF-8 pingo ls)
assert_contains "$out" "Nenhum repositório" "no config: uses detected language"

# Every key of en.sh must exist in pt-BR.sh.
missing=
while IFS= read -r line; do
  case "$line" in
    PINGO_MSG_*=*)
      k=${line%%=*}
      grep -q "^$k=" "$T_ROOT/lang/pt-BR.sh" || missing="$missing $k"
      ;;
  esac
done <"$T_ROOT/lang/en.sh"
assert_eq "$missing" "" "pt-BR translates every key"

# Switching language.
out=$(pingo config lang pt-BR 2>&1); st=$?
assert_status $st 0 "config lang pt-BR"
assert_contains "$out" "Idioma alterado para Português (Brasil)" "switch message in the new language"
assert_contains "$(cat "$XDG_CONFIG_HOME/pingo/config")" "lang=pt-BR" "language saved in config"
assert_contains "$(cat "$XDG_CONFIG_HOME/pingo/config")" "# Interface language" "config file has comments"
assert_contains "$(LANG=en_US.UTF-8 pingo ls)" "Nenhum repositório" "config wins over the environment"

out=$(pingo config lang klingon 2>&1); st=$?
assert_status $st 1 "unknown language is rejected"
out=$(pingo config lang ../../etc 2>&1); st=$?
assert_status $st 1 "language code cannot be a path"

# Editing the config file by hand works too.
printf '# hand edited\nlang=en\n' >"$XDG_CONFIG_HOME/pingo/config"
assert_contains "$(pingo ls)" "No repositories yet" "hand-edited config is honored"

# Custom language with partial translation -> missing keys fall back to English.
mkdir -p "$XDG_CONFIG_HOME/pingo/lang"
cat >"$XDG_CONFIG_HOME/pingo/lang/es.sh" <<'LANGEOF'
PINGO_LANG_NAME="Español"
PINGO_MSG_EMPTY='Todavía no hay repositorios.'
LANGEOF
out=$(pingo config lang 2>&1)
assert_contains "$out" "es" "custom language is listed"
assert_contains "$out" "Español" "custom language shows its name"
assert_contains "$out" "pt-BR" "built-in languages are listed"
pingo config lang es >/dev/null
out=$(pingo ls)
assert_contains "$out" "Todavía no hay repositorios." "custom translation is used"
assert_contains "$out" "Add one with" "untranslated keys fall back to English"

# Config without a lang line keeps working.
printf 'something=else\n' >"$XDG_CONFIG_HOME/pingo/config"
assert_contains "$(pingo ls)" "No repositories yet" "config without lang uses detection"
pingo config lang pt-BR >/dev/null
assert_contains "$(cat "$XDG_CONFIG_HOME/pingo/config")" "something=else" "config_set keeps other keys"

t_done
