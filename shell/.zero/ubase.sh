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

    local key pre2 pre cur rcur opts tips
    key="$1" && shift
    opts="$*" && shift
    COMPREPLY=()
    pre2=${COMP_WORDS[COMP_CWORD-2]}
    pre=${COMP_WORDS[COMP_CWORD-1]}
    cur=${COMP_WORDS[COMP_CWORD]}
    if [ "$pre" = "$key" ]; then
        tips="$opts"
    else
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

