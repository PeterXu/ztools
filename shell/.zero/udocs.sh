#!/usr/bin/env bash
#
# Author: peter@uskee.org
# Created: 2015-09-08
#


## --------------------------
## os package management tool
_zero_pm() {
    local os=`uname` pm="" plist=""
    if [ "$os" = "Darwin" ]; then
        plist="brew port"
    elif [ "$os" = "Linux" ]; then
        plist="yum aptitude apt-get"
    fi

    for k in $plist; do
        pm=`which $k 2>/dev/null` && break
    done
    [ -z "$pm" ] && return 1

    if [[ ! "$pm" =~ "brew" ]]; then
        [ `whoami` != "root" ] && pm="sudo $pm"
    fi
    $pm $*
}


## -----------------
## update for ztools
_zero_update() {
    local git=$(which git 2>/dev/null) || return 1
    (
        jump ...
        echo "[*] Entering <$(pwd)> ..."
        echo "[*] Then auto-update will start ..."
        $git checkout --detach
        $git branch | grep master 2>/dev/null 1>&1 && $git branch -D master
        $git fetch origin master
        $git checkout -b master origin/master
        echo
    )
    return 0
}


## --------------
## set for ztools
_zero_set() {
    local action sh
    [ $# -eq 1 ] && action="$1"
    sh=$(which bash 2>/dev/null) || return 1
    (
        jump ...
        echo "[*] Entering <$(pwd)> ..."
        echo "[*] Then set for shell ..."
        $sh zero_setting.sh $action
        [ -f $ZBASH ] && source $ZBASH
    )
    return 0
}


## ---------------------------
## print all ztools commands
_zhelp_pnx() {
    local max=7
    local pos=0
    local ulist=($*)
    local len=${#ulist[@]}
    while [ $len -gt $pos ]; do
        local tmp
        if [ $len -gt $max ]; then
            tmp=${ulist[@]:$pos:$max} && pos=$((pos+max))
        else
            tmp=${ulist[@]} && pos=$len
        fi
        echo "        => "${tmp##\n}
    done
}
_zero_help() {
    if [ $# -eq 1 ]; then
        local hfunc="${_HELP_PREFIX}$1"
        hfunc=${hfunc//-/_}
        declare -f "$hfunc" >/dev/null && eval "$hfunc" || printf "[WARN] no help for <$1>\n\n"
        return 0
    fi

    local index=0 helps="" item ulist1 ulist2 hlist 
    for item in $_SH_LIST; do
        item="$HOME/.zero/$item"
        ulist1=$(cat $item | grep "^[a-z][a-z_-]\+() " | awk -F" " '{print $1}')
        ulist2=$(cat $item | grep "^alias [a-z][a-z_-]\+=" | awk -F"=" '{print $1}' | sed 's#alias ##')
        if [ ${#ulist1} -gt 0 -o ${#ulist2} -gt 0 ]; then
            echo "[$index] $(basename $item) tools:"
            _zhelp_pnx "${ulist1}"
            _zhelp_pnx "${ulist2}"
            index=$((index+1))
        fi

        hlist=$(cat $item | grep "^${_HELP_PREFIX}[a-z_]\+() " | awk -F"(" '{print $1}')
        for item in $hlist; do
            item=${item/#${_HELP_PREFIX}/}
            item=${item//_/-}
            [ "$helps" = "" ] && helps="$item" || helps="$helps $item"
        done
    done
    printf "\n[*] Help [key]:\n"
    _zhelp_pnx "$helps"
    echo
}

## To parse functions with prefix "__help_xxx".
_Help() {
    local helps="" item hlist
    for item in $_SH_LIST; do
        item="$HOME/.zero/$item"
        hlist=$(cat $item | grep "^${_HELP_PREFIX}[a-z_]\+() " | awk -F"(" '{print $1}')
        for item in $hlist; do
            item=${item/#${_HELP_PREFIX}/}
            item=${item//_/-}
            [ "$helps" = "" ] && helps="$item" || helps="$helps $item"
        done
    done
    _tablist "Help" "$helps"
}


## -----------------
## string regex help
_regex_pnx() {
    if [ $# -eq 4 ]; then
        printf "     %-24s%s %-16s%s\n"    "$1" "$2" "$3," "$4"
    else
        printf "$*\n"
    fi
}
__help_regex() {
    local str="abcde.abcde"
    _regex_pnx  "usage:  e.g., str=\"${str}\""
    _regex_pnx  "  0. strlen"
    _regex_pnx  "expr \"\$str\" : \".*\""  "=>"  "$(expr "$str" : ".*")" "the length of string"
    _regex_pnx  "\${#str}"        "=>"  "${#str}"       "the length of string"
    _regex_pnx
    _regex_pnx  "  1. substr"
    _regex_pnx  "\${str:2}"       "=>"  "${str:2}"      "[2, the right end]"
    _regex_pnx  "\${str:2:3}"     "=>"  "${str:2:3}"    "[2, 5(from the 2th+3)]"
    _regex_pnx  "\${str:(-6):5}"  "=>"  "${str:(-6):5}" "[0, (-6)from the right end]"
    _regex_pnx  "\${str#a*c}"     "=>"  "${str#a*c}"    "del the shortest from the leftmost <#>"
    _regex_pnx  "\${str##a*c}"    "=>"  "${str##a*c}"   "del the longest from the leftmost <#>"
    _regex_pnx  "\${str%c*e}"     "=>"  "${str%c*e}"    "del the shortest from the right end <%>"
    _regex_pnx  "\${str%%c*e}"    "=>"  "${str%%c*e}"   "del the longest from the right end <%>"
    _regex_pnx
    _regex_pnx  "  2. replace"
    _regex_pnx  "\${str/bcd/x}"   "=>"  "${str/bcd/x}"  "the first matched from the leftmost"
    _regex_pnx  "\${str//bcd/x}"  "=>"  "${str//bcd/x}" "all matched string from the leftmost"
    _regex_pnx  "\${str/#bcd/x}"  "=>"  "${str/#bcd/x}" "the leftmost: 'bcd'"
    _regex_pnx  "\${str/#abc/x}"  "=>"  "${str/#abc/x}" "the leftmost: 'abc'"
    _regex_pnx  "\${str/%bcd/x}"  "=>"  "${str/%bcd/x}" "the right end: 'bcd'"
    _regex_pnx  "\${str/%cde/x}"  "=>"  "${str/%cde/x}" "the right end: 'cde'"
    _regex_pnx
    _regex_pnx  "  3. compare - logic true"
    _regex_pnx  "     [[ "$str" == "a*" ]]"
    _regex_pnx  "     [[ "$str" =~ .*\.abcde ]]"
    _regex_pnx  "     [[ \"11\" < \"2\" ]]"
    _regex_pnx

    local fpath="/tmp/README.md" fname="README.md"
    _regex_pnx  "  e.g. fpath=\"$fpath\" && fname=\"$fname\""
    _regex_pnx  "echo \${fpath##*/}"      "=>"  "${fpath##*/}"  "get the file"
    _regex_pnx  "echo \${fpath%/*}"       "=>"  "${fpath%/*}"   "get the path"
    _regex_pnx  "echo \${fname%%.*}"      "=>"  "${fname%%.*}"  "get the file basename" 
    _regex_pnx  "echo \${fname##*.}"      "=>"  "${fname##*.}"  "get the file extension name" 
    _regex_pnx  "echo -e \${fname/./'\t'}"  "=>"  "$(echo -e ${fname/./'\t'})" "replace '.' with tab"
    _regex_pnx
}


### init docs
__init_docs() {
    export _HELP_PREFIX="__help_"

    alias zpm="_zero_pm"
    alias zero-update="_zero_update"
    alias zero-set="_zero_set"
    alias Help="_zero_help"

    complete -F _Help Help
}

