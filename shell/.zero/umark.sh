#!/usr/bin/env bash
#

export _MARKPATH="$HOME/.marks"

__help_mark() {
    local opt="jump,mark,unmark,marks,marks-broken,unmark-all,unmark-broken"
    [ $# -gt 0 ] && opt="$*"
    echo "usage:"
    [[ "$opt" =~ "jump" ]]              && echo "       jump [name]"
    [[ "$opt" =~ "mark," ]]             && echo "       mark [name]"
    [[ "$opt" =~ "unmark" ]]            && echo "       unmark [name]"
    [[ "$opt" =~ "marks" ]]             && echo "       marks"
    [[ "$opt" =~ "marks-broken" ]]      && echo "       marks-broken"
    [[ "$opt" =~ "unmark-all" ]]        && echo "       unmark-all"
    [[ "$opt" =~ "unmark-broken" ]]     && echo "       unmark-broken"
    echo
    return 0
}

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
                cd -P "$_MARKPATH/$1" 2>/dev/null && r=1;;
        esac
    fi
    [ $r -ne 1 ] && echo "No such mark: $*"
}
mark() { 
    [ $# -gt 1 ] && __help_mark "mark," && return
    [ $# -eq 0 ] && iname="$_MARKPATH/`basename $(pwd)`"
    [ $# -eq 1 ] && iname="$_MARKPATH/$1"
    [ -h "$iname" ] && rm -f "$iname"    # rm symbolic file
    [ -e "$iname" ] && rm -ir "$iname"   # rm file with propmpt

    mkdir -p "$_MARKPATH"
    [ ! -e "$iname" ] && ln -s "$(pwd)" "$iname"
}
unmark() { 
    [ $# -gt 1 ] && __help_mark unmark && return
    [ $# -eq 0 ] && iname="$_MARKPATH/`basename $(pwd)`"
    [ $# -eq 1 ] && iname="$_MARKPATH/$1"
    [ -h "$iname" ] && rm -i "$iname"
}
marks() {
    ls -l "$_MARKPATH" 2>/dev/null | sed 's/  */ /g' 2>/dev/null | cut -d' ' -f9- 2>/dev/null
    echo
}

_marks_broken() {
    echo
    inames=`ls --color=never "$_MARKPATH" 2>/dev/null || ls "$_MARKPATH" 2>/dev/null`
    for iname in $inames; do
        rname=`ls -l "$_MARKPATH" 2>/dev/null | grep "$iname" | sed 's/  */ /g' 2>/dev/null | cut -d' ' -f9- 2>/dev/null`
        file "$_MARKPATH/$iname" | grep -q "broken symbolic"
        [ $? -eq 0 ] && echo "broken symbolic: $rname"
    done
}
alias marks-broken="_marks_broken"

_unmark_all() {
    printf "Remove all marks (y/n)? " && read ch 
    [ "$ch" != "y" ] && return
    printf "Are you sure (y/n)? " && read ch 
    [ "$ch" != "y" ] && return
    inames=`ls --color=never "$_MARKPATH" 2>/dev/null || ls "$_MARKPATH" 2>/dev/null`
    for iname in $inames; do
        [ -h "$_MARKPATH/$iname" ] && rm -f "$_MARKPATH/$iname"
    done
}
alias unmark-all="_unmark_all"

_unmark_broken() {
    printf "Remove all broken marks (y/n)? " && read ch 
    [ "$ch" != "y" ] && return
    inames=`ls --color=never "$_MARKPATH" 2>/dev/null || ls "$_MARKPATH" 2>/dev/null`
    for iname in $inames; do
        file "$_MARKPATH/$iname" | grep -q "broken symbolic"
        [ $? -eq 0 ] && echo "broken symbolic: $iname" && rm -f "$_MARKPATH/$iname"
    done
}
alias unmark-broken="_unmark_broken"

_jump() {
    local opts
    opts=`ls --color=never "$_MARKPATH" 2>/dev/null || ls "$_MARKPATH" 2>/dev/null`
    _tablist "jump" "$opts"
}
_unmark() {
    local opts
    opts=`ls --color=never "$_MARKPATH" 2>/dev/null || ls "$_MARKPATH" 2>/dev/null`
    _tablist "unmark" "$opts"
}

complete -F _jump jump
complete -F _unmark unmark

