# shellcheck shell=bash
# Tab completion for pingo in bash (loaded by pingo.sh).

_pingo_bash_complete() {
  local cur=${COMP_WORDS[COMP_CWORD]} first=${COMP_WORDS[1]:-} words= IFS=$'\n'
  COMPREPLY=()
  if [ "$COMP_CWORD" -eq 1 ]; then
    words=$(_pingo_completion_words)
  else
    case "$first" in
      rm | remove | rename)
        [ "$COMP_CWORD" -eq 2 ] && words=$(_pingo_completion_names)
        ;;
      pull)
        [ "$COMP_CWORD" -eq 2 ] && words=$(_pingo_completion_pull)
        ;;
      mv | move)
        [ "$COMP_CWORD" -eq 2 ] && words=$(_pingo_completion_names)
        ;;
      add)
        if [ "$COMP_CWORD" -eq 2 ]; then
          # shellcheck disable=SC2207
          COMPREPLY=($(compgen -d -- "$cur"))
          return 0
        fi
        ;;
      config)
        if [ "$COMP_CWORD" -eq 2 ]; then
          words=lang
        elif [ "$COMP_CWORD" -eq 3 ] && [ "${COMP_WORDS[2]}" = lang ]; then
          _pingo_init
          _pingo_langs
          words=$_PINGO_LANGS
        fi
        ;;
    esac
  fi
  # shellcheck disable=SC2207
  [ -n "$words" ] && COMPREPLY=($(compgen -W "$words" -- "$cur"))
  return 0
}

complete -o filenames -F _pingo_bash_complete pingo 2>/dev/null || complete -F _pingo_bash_complete pingo
