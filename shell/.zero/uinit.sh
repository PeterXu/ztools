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
        setopt shwordsplit
        #if type emulate >/dev/null 2>/dev/null; then emulate bash; fi
        tmp="/usr/local/share/zsh"
        if [ -f "$tmp" ]; then
            chmod -R 755 $tmp || echo "[FAILED]: chmod -R 755 $tmp"
        fi
        autoload -U +X compinit && compinit
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
    [ "$_UNAME" = "Darwin" ] && _SH_LIST="$_SH_LIST mac_network.sh" 

    local item
    for item in $_SH_LIST; do
        item="$HOME/.zero/$item"
        [ ! -f "$item" ] && continue
        source $item
        local func_list=$(cat $item | grep "^${_INIT_PREFIX}[a-z_]\+() " | awk -F"(" '{print $1}')
        for fn in $func_list; do
            eval $fn
        done
    done
}


_g_init_init

