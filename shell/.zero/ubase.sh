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

## trim left/right spaces
_trim() {
    [ $# -eq 1 ] && echo "$1" | sed 's/^[ \t]*//' | sed 's/[ \t]*$//'
}
_triml() {
    [ $# -eq 1 ] && echo "$1" | sed 's/^[ \t]*//'
}
_trimr() {
    [ $# -eq 1 ] && echo "$1" | sed 's/[ \t]*$//'
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
            #_printx @green "\n=>$opt, $rcur, $tip<=\n"
        done
    fi
    #_printx @red "\n=>$pre2,$pre,$key: $tips<=\n"
    COMPREPLY=($(compgen -W "$tips" -- "$cur"))
}
_tablist2() {
    [ $# -ne 2 ] && return

    local cur opts tips
    opts="$*" && shift

    COMPREPLY=()
    cur=${COMP_WORDS[COMP_CWORD]}
    [ "$cur" = ":" ] && cur=""
    tips="$opts"

    COMPREPLY=($(compgen -W "$tips" -- "$cur"))
}
_tablist3() {
    [ $# -ne 3 ] && return

    local key cur opts copts
    key="$1" && shift
    opts="$1" && shift
    copts="$*" && shift

    cur=${COMP_WORDS[COMP_CWORD]}
    if [ "${cur:0:2}" = "./" ]; then
        _tablist2 "$key" "$copts"
    else
        _tablist2 "$key" "$opts"
    fi
}

