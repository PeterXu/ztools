#!/usr/bin/env bash
#

export MARKPATH="$HOME/.marks"

jump() { 
    local r=0
    if [ $# -eq 0 ]; then
        cd 2>/dev/null && r=1
    elif [ $# -eq 1 ]; then
        case "$1" in
            -|..) 
                cd $1 && r=1;;
            ...) 
                cd -P "$ZTOOLS" 2>/dev/null && r=1;;
            *) 
                cd -P "$MARKPATH/$1" 2>/dev/null && r=1;;
        esac
    fi
    [ $r -ne 1 ] && echo "No such mark: $*"
}
mark() { 
    [ $# -gt 1 ] && echo "Usage: mark [name]" && return
    [ $# -eq 0 ] && iname="$MARKPATH/`basename $(pwd)`"
    [ $# -eq 1 ] && iname="$MARKPATH/$1"
    [ -h "$iname" ] && rm -f "$iname"    # rm symbolic file
    [ -e "$iname" ] && rm -ir "$iname"   # rm file with propmpt

    mkdir -p "$MARKPATH"
    [ ! -e "$iname" ] && ln -s "$(pwd)" "$iname"
}
unmark() { 
    [ $# -gt 1 ] && echo "Usage: unmark [name]" && return
    [ $# -eq 0 ] && iname="$MARKPATH/`basename $(pwd)`"
    [ $# -eq 1 ] && iname="$MARKPATH/$1"
    [ -h "$iname" ] && rm -i "$iname"
}
marks() {
    ls -l "$MARKPATH" 2>/dev/null | sed 's/  */ /g' 2>/dev/null | cut -d' ' -f9- 2>/dev/null
}

marks_broken() {
    echo
    inames=`ls --color=never "$MARKPATH" 2>/dev/null || ls "$MARKPATH" 2>/dev/null`
    for iname in $inames; do
        rname=`ls -l "$MARKPATH" 2>/dev/null | grep "$iname" | sed 's/  */ /g' 2>/dev/null | cut -d' ' -f9- 2>/dev/null`
        file "$MARKPATH/$iname" | grep -q "broken symbolic"
        [ $? -eq 0 ] && echo "broken symbolic: $rname"
    done
}
unmark_all() { 
    printf "Remove all marks (y/n)? " && read ch 
    [ "$ch" != "y" ] && return
    inames=`ls --color=never "$MARKPATH" 2>/dev/null || ls "$MARKPATH" 2>/dev/null`
    for iname in $inames; do
        [ -h "$MARKPATH/$iname" ] && rm -f "$MARKPATH/$iname"
    done
}
unmark_broken() {
    printf "Remove all broken marks (y/n)? " && read ch 
    [ "$ch" != "y" ] && return
    inames=`ls --color=never "$MARKPATH" 2>/dev/null || ls "$MARKPATH" 2>/dev/null`
    for iname in $inames; do
        file "$MARKPATH/$iname" | grep -q "broken symbolic"
        [ $? -eq 0 ] && echo "broken symbolic: $iname" && rm -f "$MARKPATH/$iname"
    done
}

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
_jump() {
    local opts
    opts=`ls --color=never "$MARKPATH" 2>/dev/null || ls "$MARKPATH" 2>/dev/null`
    _tablist "jump" "$opts"
}
_unmark() {
    local opts
    opts=`ls --color=never "$MARKPATH" 2>/dev/null || ls "$MARKPATH" 2>/dev/null`
    _tablist "unmark" "$opts"
}

complete -F _jump jump
complete -F _unmark unmark

