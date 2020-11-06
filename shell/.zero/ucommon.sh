#!/usr/bin/env bash


__init_common() {
    # For general alias
    #[ "$_UNAME" != "Darwin" ] && alias cp='cp -i'
    [ "$_UNAME" = "Darwin" ] && alias ls='ls -G'
    which gls 2>/dev/null 1>&2 && alias ls='gls --color=auto'
    alias ll='ls -l'
    #alias mv='mv -i'
    #alias rm='rm -i'
    alias cls='clear'
    alias grep='grep --color=auto'

    # for macos completion
    if [ "$_UNAME" = "Darwin" -a "$_SHNAME" = "bash" ]; then
        local item="/usr/local/etc/bash_completion"
        [ -f "$item" ] && source $item
    fi

    # For shell extending
    local items="git-completion.bash git-prompt.sh"
    for k in $items; do
        item="$HOME/.zero/$item"
        [ -f "$item" ] && source $item
    done
}

