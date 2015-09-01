#!/usr/bin/env bash
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


## ------------
## for bash map
_map_help() {
    local opt="set,get,del"
    [ $# -gt 0 ] && opt="$*"
    echo "usage:"
    [[ "$opt" =~ "set" ]] && echo "       mapset vname key value"
    [[ "$opt" =~ "get" ]] && echo "       mapget vname key"
    [[ "$opt" =~ "del" ]] && echo "       mapdel vname key"
    echo
    return 0
}
alias map-help="_map_help"
mapset() {
    [ $# -ne 3 ] && _map_help set && return 1
    local vname=`_make_vname "${1}_${2}"` || return 1
    eval "${vname}=\"${3}\""
}
mapget() {
    [ $# -ne 2 ] && _map_help get && return 1
    local vname=`_make_vname "${1}_${2}"` || return 1
    declare -p ${vname} 2>/dev/null 1>&2 || return 1
    eval "echo \${${vname}}"
}
mapdel() {
    [ $# -ne 2 ] && _map_help del && return 1
    local vname=`_make_vname "${1}_${2}"` || return 1
    eval "unset ${vname}"
}


## ---------------------------
## print all avaiable commands
_zlist_pnx() {
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
zlist() {
    local index=0
    local flist="$HOME/.vim/umark.sh $HOME/.vim/umisc.sh $HOME/.vim/udocker.sh"
    for item in $flist; do
        local ulist1=$(cat $item | grep "^[a-z][a-z_-]\+() " | awk -F" " '{print $1}')
        local ulist2=$(cat $item | grep "^alias [a-z][a-z_-]\+=" | awk -F"=" '{print $1}' | sed 's#alias ##')
        if [ ${#ulist1} -gt 0 -o ${#ulist2} -gt 0 ]; then
            echo "[$index] $(basename $item) tools:"
            _zlist_pnx "${ulist1}"
            _zlist_pnx "${ulist2}"
            index=$((index+1))
        fi
    done
    echo
}


## -----------------
## autoupdate ztools
_ztools_update() {
    git=$(which git 2>/dev/null) || return 1
    (
        jump ...
        echo "Entering <$(pwd)> ..."
        echo "Then auto-update will start ..."
        $git pull
        echo
    )
    return 0
}
alias ztools-update="_ztools_update"


## -------------
## ssh with tips
_ssh() {
    local opts
    opts=`cat $HOME/.ssh/config 2>/dev/null  | grep "Host " | awk '{print $2}'`
    _tablist "ssh" "$opts"
}
complete -F _ssh ssh


## ------------------------
## ps -ef order by %mem/rsz
_ps_ef() {
    local nth str opt
    [ $# -lt 2 -o $# -gt 3 ] && return 1
    nth=$1 && str="$2"
    [ $# -eq 3 ] && opt=$3

    local opts
    if [ "$(uname)" = "Darwin" ]; then
        opts='uid,pid,ppid,stime,time,%cpu,%mem,vsz,rss,comm' 
    else
        opts='euid,pid,ppid,stime,time,%cpu,%mem,vsz,rsz,comm'
    fi
    ps -eo $opts | sort -k $nth -n -s $opt
    if [[ ! "$opt" =~ "-r" ]]; then
        ps -eo $opts | grep "$str"
    fi
}
alias ps-mem="_ps_ef 9 %MEM"
alias ps-cpu="_ps_ef 6 %CPU"
alias ps-pid="_ps_ef 2 ' PID'"
alias ps-time="_ps_ef 4 ' TIME'"
alias ps-stime="_ps_ef 5 STIME"
alias psr-stime="_ps_ef 5 STIME -r"
alias psr-pid="_ps_ef 2 PID -r"


## -----------------
## string regex help
_regex_pnx() {
    if [ $# -eq 4 ]; then
        printf "     %-24s%s %-16s%s\n"    "$1" "$2" "$3," "$4"
    else
        printf "$*\n"
    fi
}
_regex_help() {
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
alias regex-help="_regex_help"

