#!/usr/bin/env bash

_git_prepare() {
    local ret=1
    which git 2>/dev/null 1>&2 && ret=0
    local fver="/tmp/.zero_git_version"
    if [ $ret -eq 0 ]; then
        [ ! -f $fver ] && git --version > $fver
    else
        rm -f $fver
    fi
}

_git_init() {
    which git 2>/dev/null 1>&2 || return
    local fver="/tmp/.zero_git_version"
    [ ! -f $fver ] && return
    if [ "$_SHNAME" = "bash" ]; then
        #ver0=2
        ver0=$(cat $fver | awk '{print $3}' | awk -F"." '{print $1}')
        #ver1=$(cat $fver | awk '{print $3}' | awk -F"." '{print $2}')
        local items="git-completion.bash git-prompt.sh"
        [ $ver0 -lt 2 ] && items="git-completion-v18.bash git-prompt-v18.sh"
        for k in $items; do
            item="$HOME/.zero/$k"
            [ -f "$item" ] && source $item
        done
    fi
}

_docker_init() {
    # For shell extending
    local ret=1
    which docker 2>/dev/null 1>&2 && ret=0
    if [ $ret -eq 0 -a "$_SHNAME" = "bash" ]; then
        local items="docker.bash-completion docker-compose.bash-completion"
        for k in $items; do
            item="$HOME/.zero/$k"
            [ -f "$item" ] && source $item
        done
    fi
}

__init_common() {
    # For general alias
    #[ "$_UNAME" != "Darwin" ] && alias cp='cp -i'
    local ls0='ls --color=auto'
    [ "$_UNAME" = "Darwin" ] && ls0='ls -G'
    which gls 2>/dev/null 1>&2 && ls0='gls --color=auto'
    local date0='date'
    which gdate 2>/dev/null 1>&2 && date0='gdate'

    alias ls="$ls0"
    alias ll='ls -l'
    alias date="$date0"
    #alias mv='mv -i'
    #alias rm='rm -i'
    alias cls='clear'
    alias grep='grep --color=auto'

    # for macos completion
    if [ "$_UNAME" = "Darwin" -a "$_SHNAME" = "bash" ]; then
        local item="/usr/local/etc/bash_completion"
        [ -f "$item" ] && source $item
    fi

    _git_prepare >/dev/null 2>&1 &
    _git_init
    _docker_init
}

