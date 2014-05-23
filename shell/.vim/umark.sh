#!/bin/sh
#

export MARKPATH=$HOME/.marks

function jump { 
    [ $# -eq 1 ] && cd -P "$MARKPATH/$1" 2>/dev/null || echo "No such mark: $1"
}
function mark { 
    mkdir -p "$MARKPATH" && ln -s "$(pwd)" "$MARKPATH/$1"
}
function unmark { 
    [ $# -gt 1 ] && echo "Usage: unmark [name]" && return
    [ $# -eq 0 ] && iname="$MARKPATH/`basename $(pwd)`"
    [ $# -eq 1 ] && iname="$MARKPATH/$1"

    [ -h "$iname" ] && rm -i "$iname"
}
function marks {
    mkdir -p "$MARKPATH" && ls -l "$MARKPATH" | sed 's/  */ /g' | cut -d' ' -f9-
}

_jump() {
    local pre cur opts tips
    COMPREPLY=()
    pre=${COMP_WORDS[COMP_CWORD-1]}
    cur=${COMP_WORDS[COMP_CWORD]}
    opts=`mkdir -p "$MARKPATH" && ls --color=never "$MARKPATH" 2>/dev/null || ls "$MARKPATH" 2>/dev/null`
    [ "$cur" = "" ] && tips="$opts" ||
        for opt in $opts; do
            tip=${opt/$cur/} && [ "$tip" != "$opt" ] && tips+="$cur$tip"
        done
    COMPREPLY=($(compgen -W "$tips" -- "$cur"))
}
_unmark() {
    _jump
}

complete -F _jump jump
complete -F _unmark unmark

