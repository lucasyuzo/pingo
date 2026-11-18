# Tab completion for pingo in zsh (loaded by pingo.sh).

_pingo_zsh_complete() {
  setopt localoptions nonomatch noksharrays
  local -a items
  if (( CURRENT == 2 )); then
    items=(${(f)"$(_pingo_completion_words)"})
    compadd -a items
    return
  fi
  case "${words[2]}" in
    rm|remove|rename|mv|move)
      if (( CURRENT == 3 )); then
        items=(${(f)"$(_pingo_completion_names)"})
        compadd -a items
      fi
      ;;
    pull)
      if (( CURRENT == 3 )); then
        items=(${(f)"$(_pingo_completion_pull)"})
        compadd -a items
      fi
      ;;
    add)
      (( CURRENT == 3 )) && _files -/
      ;;
    config)
      if (( CURRENT == 3 )); then
        compadd lang
      elif (( CURRENT == 4 )) && [[ "${words[3]}" == lang ]]; then
        _pingo_init
        _pingo_langs
        items=(${(f)_PINGO_LANGS})
        compadd -a items
      fi
      ;;
  esac
}

# compdef only exists after compinit. If it is not loaded yet (pingo sourced
# before compinit / oh-my-zsh), register on the first prompt instead.
_pingo_register_completion() {
  if (( $+functions[compdef] )); then
    compdef _pingo_zsh_complete pingo
    precmd_functions=(${precmd_functions:#_pingo_register_completion})
    return 0
  fi
  return 1
}

if ! _pingo_register_completion; then
  typeset -ga precmd_functions
  if (( ${precmd_functions[(I)_pingo_register_completion]} == 0 )); then
    precmd_functions+=(_pingo_register_completion)
  fi
fi
