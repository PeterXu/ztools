#!/usr/bin/env bash
#

_jump() { 
    local r=0 dname
    if [ $# -eq 0 ]; then
        cd 2>/dev/null && r=1
    elif [ $# -eq 1 ]; then
        case "$1" in
            -|..) cd $1 && r=1;;
            ...)  cd -P "$ZTOOLS" 2>/dev/null && r=1;;
            *)    
                  [ "$_UNAME" = "MINGW" ] && dname=$(cat "$_MARKPATH/$1") || dname="$_MARKPATH/$1"
                  cd -P "$dname" 2>/dev/null && r=1;;
        esac
    fi
    [ $r -ne 1 ] && _printx @yellow "[WARN] No such mark: $*\n\n" && return 1
}
_mark() {
    local iname
    [ $# -gt 1 ] && __help_mark "mark," && return 1
    [ $# -eq 0 ] && iname="$_MARKPATH/`basename $(pwd)`"
    [ $# -eq 1 ] && iname="$_MARKPATH/$1"
    [ -h "$iname" ] && rm -f "$iname"    # rm symbolic file
    [ -e "$iname" ] && rm -ir "$iname"   # rm file with propmpt
    [ -e "$iname" ] && return 0

    mkdir -p "$_MARKPATH"
    [ "$_UNAME" = "MINGW" ] && echo "$(pwd)" > "$iname" || ln -s "$(pwd)" "$iname"
}
_pmark() {
    local dname
    [ $# -ge 1 ] && __help_mark unmark && return
    dname="$(pwd)"
    if [ "$_UNAME" = "MINGW" ]; then
        local inames=`ls --color=never "$_MARKPATH" 2>/dev/null || ls "$_MARKPATH" 2>/dev/null`
        for iname in $inames; do
            local rname=$(cat "$_MARKPATH/$iname")
            [ "$dname" = "$rname" ] && echo "$iname -> $rname"
        done
    else
        ls -l "$_MARKPATH" 2>/dev/null | sed 's/  */ /g' 2>/dev/null | cut -d' ' -f9- 2>/dev/null | grep "> $dname$"
    fi
    echo
}
_unmark() {
    local iname
    [ $# -gt 1 ] && __help_mark unmark && return
    [ $# -eq 0 ] && iname="$_MARKPATH/`basename $(pwd)`"
    [ $# -eq 1 ] && iname="$_MARKPATH/$1"
    [ -e "$iname" ] && rm -i "$iname"
}
_marks() {
    if [ "$_UNAME" = "MINGW" ]; then
        local inames=`ls --color=never "$_MARKPATH" 2>/dev/null || ls "$_MARKPATH" 2>/dev/null`
        for iname in $inames; do
            local rname=$(cat "$_MARKPATH/$iname")
            echo "$iname -> $rname"
        done
    else
        ls -l "$_MARKPATH" 2>/dev/null | sed 's/  */ /g' 2>/dev/null | cut -d' ' -f9- 2>/dev/null
    fi
    echo
}

_marks_broken() {
    echo
    [ "$_UNAME" = "MINGW" ] && return 0
    local inames=`ls --color=never "$_MARKPATH" 2>/dev/null || ls "$_MARKPATH" 2>/dev/null`
    for iname in $inames; do
        rname=`ls -l "$_MARKPATH" 2>/dev/null | grep "$iname" | sed 's/  */ /g' 2>/dev/null | cut -d' ' -f9- 2>/dev/null`
        file "$_MARKPATH/$iname" | grep -q "broken symbolic"
        [ $? -eq 0 ] && _printx @yellow "[.] broken symbolic: $rname\n"
    done
}

_unmark_all() {
    local ch
    _printx @red "[*] Remove all marks (y/n)? " && read ch 
    [ "$ch" != "y" ] && return 0
    _printx @red "[*] Are you sure (y/n)? " && read ch 
    [ "$ch" != "y" ] && return 0
    local inames=`ls --color=never "$_MARKPATH" 2>/dev/null || ls "$_MARKPATH" 2>/dev/null`
    for iname in $inames; do
        [ -f "$_MARKPATH/$iname" ] && rm -f "$_MARKPATH/$iname"
    done
}

_unmark_broken() {
    [ "$_UNAME" = "MINGW" ] && return 0
    local ch
    _printx @red "[*] Remove all broken marks (y/n)? " && read ch 
    [ "$ch" != "y" ] && return 0
    local inames=`ls --color=never "$_MARKPATH" 2>/dev/null || ls "$_MARKPATH" 2>/dev/null`
    for iname in $inames; do
        file "$_MARKPATH/$iname" | grep -q "broken symbolic"
        [ $? -eq 0 ] && _printx @green "[-] broken symbolic: $iname\n" && rm -f "$_MARKPATH/$iname"
    done
}


## tab tips
_jump_tips() {
    local opts=`ls --color=never "$_MARKPATH" 2>/dev/null || ls "$_MARKPATH" 2>/dev/null`
    _tablist "jump" "$opts"
}
_unmark_tips() {
    local opts=`ls --color=never "$_MARKPATH" 2>/dev/null || ls "$_MARKPATH" 2>/dev/null`
    _tablist "unmark" "$opts"
}



### init mark
__init_mark() {
    _MARKPATH="$HOME/.marks"

    alias jump="_jump"
    alias mark="_mark"
    alias pmark="_pmark"
    alias unmark="_unmark"
    alias marks="_marks"
    alias marks-broken="_marks_broken"
    alias unmark-all="_unmark_all"
    alias unmark-broken="_unmark_broken"

    _completex _jump_tips jump
    _completex _unmark_tips unmark
}


### help mark
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

