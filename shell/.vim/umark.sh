#!/bin/sh
#

export MARKPATH=$HOME/.marks

function jump { 
    cd -P "$MARKPATH/$1" 2>/dev/null || echo "No such mark: $1"
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

