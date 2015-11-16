#!/usr/bin/env bash
#
# Author: peter@uskee.org
# Created: 2015-09-09
#


## -------------
## escape string
_escape() {
    [ $# -ne 1 ] && return 1
    local name=`printf ${1} | tr [:space:]- _`
    local trim=`printf $name | tr -d [:alnum:]_`
    echo $name | tr -d "$trim"
    return 0
}
## make variable name
_make_vname() {
    [ $# -eq 1 ] && _escape "_g_${1}" || return 1
}
## make real name
_make_rname() {
    [ $# -eq 1 ] && _escape "${1}" || return 1
}


## ------------------------------------
## For bash tab tips: _tablist key opts
_tablist() {
    [ $# -ne 2 ] && return

    local key pre2 pre cur rcur opts tips
    key="$1" && shift
    opts="$*" && shift
    COMPREPLY=()
    pre=${COMP_WORDS[COMP_CWORD-1]}
    cur=${COMP_WORDS[COMP_CWORD]}
    if [ "$pre" = "$key" ]; then
        tips="$opts"
    else
        pre2=${COMP_WORDS[COMP_CWORD-2]}
        [ "$pre2" = "$key" ] && rcur="$pre$cur" || rcur="$pre2$pre$cur"
        [ "$cur" = ":" ] && cur=""
        
        for opt in $opts; do
            tip=${opt/$rcur/} && [ "$tip" != "$opt" ] && tips+="$cur$tip "
            #printx @green "\n=>$opt, $rcur, $tip<=\n"
        done
    fi
    #printx @red "\n=>$pre2,$pre,$key: $tips<=\n"
    COMPREPLY=($(compgen -W "$tips" -- "$cur"))
}

