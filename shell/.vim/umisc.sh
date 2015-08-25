#!/usr/bin/env bash
#

_make_vname() {
    [ $# -ne 1 ] && return 1
    local vname=`echo g_${1} | tr [:space:]- _`
    local vtrim=`echo $vname | tr -d [:alnum:]_`
    echo $vname | tr -d "$vtrim"
    return 0
}


## for bash map
map_help() {
    local opt
    [ $# -eq 0 ] && opt="set,get,del" || opt="$*"
    echo "usage:"
    [[ "$opt" =~ "set" ]] && echo "       map_set map_name map_key map_val"
    [[ "$opt" =~ "get" ]] && echo "       map_get map_name map_key"
    [[ "$opt" =~ "del" ]] && echo "       map_del map_name map_key"
    return 0
}

map_set() {
    [ $# -ne 3 ] && map_help set && return 1
    local vname=`_make_vname "${1}_${2}"` || return 1
    eval "${vname}=\"${3}\""
}

map_get() {
    [ $# -ne 2 ] && map_help get && return 1
    local vname=`_make_vname "${1}_${2}"` || return 1
    declare -p ${vname} 2>/dev/null 1>&2 || return 1
    eval "echo \${${vname}}"
}

map_del() {
    [ $# -ne 2 ] && map_help del && return 1
    local vname=`_make_vname "${1}_${2}"` || return 1
    eval "unset ${vname}"
}


## print all avaiable commands
zlist() {
    local ulist1 ulist2
    local index=0
    local flist="$HOME/.vim/umark.sh $HOME/.vim/umisc.sh $HOME/.vim/udocker.sh"
    for item in $flist; 
    do
        ulist1=$(cat $item | grep "^[a-z][a-z_-]\+() " | awk -F" " '{print $1}')
        ulist2=$(cat $item | grep "^alias [a-z][a-z_-]\+=" | awk -F"=" '{print $1}' | sed 's#alias ##')
        if [ ${#ulist1} -gt 0 -o ${#ulist2} -gt 0 ]; then
            echo "[$index] $(basename $item) tools:"
            [ ${#ulist1} -gt 0 ] && echo "        => "${ulist1##\n}
            [ ${#ulist2} -gt 0 ] && echo "        => "${ulist2##\n}
            index=$((index+1))
        fi
    done
}


## ssh with tips
_ssh() {
    local opts
    opts=`cat $HOME/.ssh/config 2>/dev/null  | grep "Host " | awk '{print $2}'`
    _tablist "ssh" "$opts"
}
complete -F _ssh ssh


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


_printx() {
    if [ $# -eq 4 ]; then
        printf "     %-24s%s %-16s%s\n"    "$1" "$2" "$3," "$4"
    else
        printf "$*\n"
    fi
}

## string regex help
regex_help() {
    local str="abcde.abcde"
    _printx     "usage:  e.g., str=\"${str}\""
    _printx     "  0. strlen"
    _printx     "expr \"\$str\" : \".*\""  "=>"  "$(expr "$str" : ".*")" "the length of string"
    _printx     "\${#str}"        "=>"  "${#str}"       "the length of string"
    _printx
    _printx     "  1. substr"
    _printx     "\${str:2}"       "=>"  "${str:2}"      "[2, the right end]"
    _printx     "\${str:2:3}"     "=>"  "${str:2:3}"    "[2, 5(from the 2th+3)]"
    _printx     "\${str:(-6):5}"  "=>"  "${str:(-6):5}" "[0, (-6)from the right end]"
    _printx     "\${str#a*c}"     "=>"  "${str#a*c}"    "del the shortest from the leftmost <#>"
    _printx     "\${str##a*c}"    "=>"  "${str##a*c}"   "del the longest from the leftmost <#>"
    _printx     "\${str%c*e}"     "=>"  "${str%c*e}"    "del the shortest from the right end <%>"
    _printx     "\${str%%c*e}"    "=>"  "${str%%c*e}"   "del the longest from the right end <%>"
    _printx
    _printx     "  2. replace"
    _printx     "\${str/bcd/x}"   "=>"  "${str/bcd/x}"  "the first matched from the leftmost"
    _printx     "\${str//bcd/x}"  "=>"  "${str//bcd/x}" "all matched string from the leftmost"
    _printx     "\${str/#bcd/x}"  "=>"  "${str/#bcd/x}" "the leftmost: 'bcd'"
    _printx     "\${str/#abc/x}"  "=>"  "${str/#abc/x}" "the leftmost: 'abc'"
    _printx     "\${str/%bcd/x}"  "=>"  "${str/%bcd/x}" "the right end: 'bcd'"
    _printx     "\${str/%cde/x}"  "=>"  "${str/%cde/x}" "the right end: 'cde'"
    _printx
    _printx     "  3. compare - logic true"
    _printx     "     [[ "$str" == "a*" ]]"
    _printx     "     [[ "$str" =~ .*\.abcde ]]"
    _printx     "     [[ \"11\" < \"2\" ]]"
    _printx

    local fpath="/tmp/README.md" fname="README.md"
    _printx     "  e.g. fpath=\"$fpath\" && fname=\"$fname\""
    _printx     "echo \${fpath##*/}"      "=>"  "${fpath##*/}"  "get the file"
    _printx     "echo \${fpath%/*}"       "=>"  "${fpath%/*}"   "get the path"
    _printx     "echo \${fname%%.*}"      "=>"  "${fname%%.*}"  "get the file basename" 
    _printx     "echo \${fname##*.}"      "=>"  "${fname##*.}"  "get the file extension name" 
    _printx     "echo -e \${fname/./'\t'}"  "=>"  "$(echo -e ${fname/./'\t'})" "replace '.' with tab"
    _printx
}


