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
    ps -eo $opts | grep "$str"
}
alias ps-mem="_ps_ef 9 %MEM"
alias ps-cpu="_ps_ef 6 %CPU"
alias ps-pid="_ps_ef 2 ' PID'"
alias ps-time="_ps_ef 4 ' TIME'"
alias ps-stime="_ps_ef 5 STIME"
alias psr-stime="_ps_ef 5 STIME -r"
alias psr-pid="_ps_ef 2 ' PID' -r"

