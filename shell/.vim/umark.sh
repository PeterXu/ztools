#!/bin/sh
#

export MARKPATH=$HOME/.marks

function jump { 
    cd -P "$MARKPATH/$1" 2>/dev/null || echo "No such mark: $1"
}
function mark { 
    mkdir -p "$MARKPATH"; ln -s "$(pwd)" "$MARKPATH/$1"
}
function unmark { 
    if [ $# -eq 0 ]; then
        cwd=`pwd`
        iname="$MARKPATH/`basename $cwd`"
    elif [ $# -eq 1 ]; then
        iname="$MARKPATH/$1"
    else
        echo "Usage: unmark [name]"; exit 0
    fi

    [ -e "$iname" ] && rm -i "$iname"
}
function marks {
    mkdir -p "$MARKPATH"
    ls -l "$MARKPATH" | sed 's/  / /g' | sed 's/  / /g' | cut -d' ' -f9-
}

