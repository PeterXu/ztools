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
    export _INIT_PREFIX="__init_"
    export _SH_LIST="ubase.sh umisc.sh umark.sh udocker.sh udocs.sh srcin.sh"

    local item funcs
    for item in $_SH_LIST; do
        item="$HOME/.zero/$item"
        source $item
        local func_list=$(cat $item | grep "^${_INIT_PREFIX}[a-z_]\+() " | awk -F"(" '{print $1}')
        for item in $func_list; do
            [ "$funcs" = "" ] && funcs="$item" || funcs="$funcs;$item"
        done
    done
    eval "$funcs"
}
_g_init_init

