#!/bin/sh
#

export MARKPATH=$HOME/.marks

function jump { 
    local r=0
    [ $# -eq 0 ] && cd -P "$ZTOOLS" 2>/dev/null && r=1
    [ $# -eq 1 ] && cd -P "$MARKPATH/$1" 2>/dev/null && r=1
    [ $r -ne 1 ] && echo "No such mark: $*"
}
function mark { 
    [ $# -gt 1 ] && echo "Usage: mark [name]" && return
    mkdir -p "$MARKPATH" && ln -s "$(pwd)" "$MARKPATH/$1"
}
function unmark { 
    [ $# -gt 1 ] && echo "Usage: unmark [name]" && return
    [ $# -eq 0 ] && iname="$MARKPATH/`basename $(pwd)`"
    [ $# -eq 1 ] && iname="$MARKPATH/$1"
    [ -h "$iname" ] && rm -i "$iname"
}
function unmarkall { 
    [ $# -ne 0 ] && echo "Usage: unmarkall" && return
    printf "Remove all marks (y/n)? " && read ch 
    [ "$ch" != "y" ] && return
    inames=`ls --color=never "$MARKPATH" 2>/dev/null || ls "$MARKPATH" 2>/dev/null`
    for iname in $inames; do
        [ -h "$MARKPATH/$iname" ] && rm -f "$MARKPATH/$iname"
    done
}
function marks {
    ls -l "$MARKPATH" 2>/dev/null | sed 's/  */ /g' 2>/dev/null | cut -d' ' -f9- 2>/dev/null
}

_tablist() {
    [ $# -ne 1 ] && return

    local key pre cur opts tips
    key="$1"
    COMPREPLY=()
    pre=${COMP_WORDS[COMP_CWORD-1]}
    cur=${COMP_WORDS[COMP_CWORD]}
    opts=`ls --color=never "$MARKPATH" 2>/dev/null || ls "$MARKPATH" 2>/dev/null`
    [ "$pre" = "$key" ] && tips="$opts" ||
        for opt in $opts; do
            tip=${opt/$cur/} && [ "$tip" != "$opt" ] && tips+="$cur$tip"
        done
    COMPREPLY=($(compgen -W "$tips" -- "$cur"))
}
_jump() {
    _tablist "jump"
}
_unmark() {
    _tablist "unmark"
}

complete -F _jump jump
complete -F _unmark unmark

