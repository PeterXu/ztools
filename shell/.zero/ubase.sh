#!/usr/bin/env bash
#
# Author: peter@uskee.org
# Created: 2015-09-09
#


## ------------------
## make variable name
_make_vname() {
    [ $# -ne 1 ] && return 1
    local vname=`echo g_${1} | tr [:space:]- _`
    local vtrim=`echo $vname | tr -d [:alnum:]_`
    echo $vname | tr -d "$vtrim"
    return 0
}


## ------------------------------------
## For bash tab tips: _tablist key opts
_tablist() {
    [ $# -ne 2 ] && return

    local key pre cur opts tips
    key="$1" && shift
    opts="$*" && shift
    COMPREPLY=()
    pre=${COMP_WORDS[COMP_CWORD-1]}
    cur=${COMP_WORDS[COMP_CWORD]}
    [ "$pre" = "$key" ] && tips="$opts" ||
        for opt in $opts; do
            tip=${opt/$cur/} && [ "$tip" != "$opt" ] && tips+="$cur$tip"
        done
    COMPREPLY=($(compgen -W "$tips" -- "$cur"))
}

