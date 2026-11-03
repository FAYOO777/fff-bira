# fff-bira v4 Nord Edition — role-aware Oh My Zsh prompt.
# Based on the Oh My Zsh 'bira' theme (MIT license).
# Requires FFF_BIRA_ROLE=cvm|pve|vm|phy before oh-my-zsh.sh is sourced.

source "$ZSH/themes/bira.zsh-theme"

case "${FFF_BIRA_ROLE:-${FAYOO_ROLE:-}}" in
  cvm) fff_bira_type='CVM'; fff_bira_type_color='#88C0D0' ;;
  pve) fff_bira_type='PVE'; fff_bira_type_color='#D08770' ;;
  vm)  fff_bira_type='VM';  fff_bira_type_color='#EBCB8B' ;;
  phy) fff_bira_type='PHY'; fff_bira_type_color='#B48EAD' ;;
  *)   fff_bira_type='UNSET'; fff_bira_type_color='#9096A0' ;;
esac

# Label text is independent of device type; only the type decides its color.
fff_bira_label="${FFF_BIRA_LABEL:-$fff_bira_type}"
if [[ -z "$fff_bira_label" || ${#fff_bira_label} -gt 24 ]]; then
  fff_bira_label="$fff_bira_type"
fi

typeset -g FFF_BIRA_PREFIX='╭─'
FFF_BIRA_PREFIX+="%F{${fff_bira_type_color}}[${fff_bira_label}]%f "
FFF_BIRA_PREFIX+='%(!.%F{#BF616A}.%F{#A3BE8C})%n%f'
FFF_BIRA_PREFIX+='%F{#B9BEC7}@%f%F{#D8DEE9}%m%f '

typeset -g FFF_BIRA_EXTRAS='$(conda_prompt_info)$(ruby_prompt_info)$(git_prompt_info)$(hg_prompt_info)$(virtualenv_prompt_info)'
if [[ " ${plugins[*]} " == *' kube-ps1 '* ]]; then
  FFF_BIRA_EXTRAS+='$(kube_ps1)'
fi

function fff_bira_precmd() {
  local last_status=$?
  emulate -L zsh -o extendedglob -o prompt_subst

  local date_format='%D{%m-%d %H:%M}'
  local right_sample="$(print -Pn -- "$date_format")"
  local -i right_width=${#right_sample}
  local path left expanded plain gap
  local -a paths=( '%~' '%3~' '%2~' '%1~' )
  local extras="$FFF_BIRA_EXTRAS"
  local bar=''
  local -i i

  for path in "${paths[@]}"; do
    left="${FFF_BIRA_PREFIX}%F{#D8DEE9}${path}%f ${extras}"
    expanded="$(print -Pn -- "$left")"
    plain="${expanded//$'\e'\[[0-9\;]##m/}"
    gap=$(( COLUMNS - ${#plain} - right_width - 1 ))
    (( gap >= 3 )) && break
  done

  if (( gap < 3 )); then
    extras=''
    left="${FFF_BIRA_PREFIX}%F{#D8DEE9}%1~%f "
    expanded="$(print -Pn -- "$left")"
    plain="${expanded//$'\e'\[[0-9\;]##m/}"
    gap=$(( COLUMNS - ${#plain} - right_width - 1 ))
  fi

  if (( gap >= 3 )); then
    for (( i = 0; i < gap; ++i )); do
      bar+='─'
    done
    PROMPT="${left}%F{#626772}${bar}%f %F{#9096A0}${date_format}%f
╰─%(!.%F{#BF616A}●.%F{#A3BE8C}○)%f "
  else
    PROMPT="${left}
╰─%(!.%F{#BF616A}●.%F{#A3BE8C}○)%f "
  fi

  if (( last_status != 0 )); then
    RPROMPT="%F{#BF616A}[${last_status}]%f"
  else
    RPROMPT=''
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd fff_bira_precmd
