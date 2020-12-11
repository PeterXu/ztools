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
    local ret=1
    which git 2>/dev/null 1>&2 && ret=0
    if [ $ret -eq 0 ]; then
        ver0=$(git --version | awk '{print $3}' | awk -F"." '{print $1}')
        #ver1=$(git --version | awk '{print $3}' | awk -F"." '{print $2}')
        local items="git-completion.bash git-prompt.sh"
        [ $ver0 -lt 2 ] && items="git-completion-v18.bash git-prompt-v18.sh"
        for k in $items; do
            item="$HOME/.zero/$k"
            [ -f "$item" ] && source $item
        done
    fi
}

