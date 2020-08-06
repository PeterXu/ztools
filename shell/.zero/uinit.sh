#!/usr/bin/env bash
#
# Author: peter@uskee.org
# Created: 2015-11-18
#


## ===================================================
## ---------------------------------------------------
## global init scripts: 
##      To call functions with prefix of "__init_xxx".
_g_init_init() {
    local kShName="sh"
    local shname=$(ps -p $$ -o comm | grep -iv comm)
    if [[ "$shname" =~ "zsh" ]]; then
        kShName="zsh"
        if type emulate >/dev/null 2>/dev/null; then emulate bash; fi
        #autoload -U compinit && compinit
        #alias complete=compdef
    elif [[ "$shname" =~ "bash" ]]; then
        kShName="bash"
    fi
    _SHNAME="$kShName"


    _INIT_PREFIX="__init_"
    _SH_LIST="ucommon.sh ubase.sh umisc.sh umark.sh udocker.sh udocs.sh srcin.sh"

    local kUname=$(uname)
    [[ "$kUname" =~ "MINGW" || "$kUname" =~ "mingw" ]] && kUname="MINGW"
    _UNAME="$kUname"

    [ "$_UNAME" = "MINGW" ] && _SH_LIST="ucommon.sh ubase.sh umark.sh"

    local item
    for item in $_SH_LIST; do
        item="$HOME/.zero/$item"
        [ ! -f "$item" ] && continue
        source $item
        local func_list=$(cat $item | grep "^${_INIT_PREFIX}[a-z_]\+() " | awk -F"(" '{print $1}')
        local initf
        for initf in $func_list; do
            eval "$initf"
        done
    done
}


_g_init_init

