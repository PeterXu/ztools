#!/usr/bin/env bash
#

_make_vname() {
    [ $# -ne 1 ] && return 1
    local vname=`echo g_${1} | tr [:space:]- _`
    local vtrim=`echo $vname | tr -d [:alnum:]_`
    echo $vname | tr -d "$vtrim"
}


## for bash map
map_usage() {
    local opt
    [ $# -eq 0 ] && opt="set,get,del" || opt="$*"
    echo "usage:"
    [[ "$opt" =~ "set" ]] && echo "       map_set map_name map_key map_val"
    [[ "$opt" =~ "get" ]] && echo "       map_get map_name map_key"
    [[ "$opt" =~ "del" ]] && echo "       map_del map_name map_key"
}

map_set() {
    [ $# -ne 3 ] && map_usage set && return 1
    local vname=`_make_vname "${1}_${2}"` || return 1
    eval "${vname}=\"${3}\""
}

map_get() {
    [ $# -ne 2 ] && map_usage get && return 1
    local vname=`_make_vname "${1}_${2}"` || return 1
    declare -p ${vname} 2>/dev/null 1>&2 || return 1
    eval "echo \${${vname}}"
}

map_del() {
    [ $# -ne 2 ] && map_usage del && return 1
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


# ps -ef order by %mem/rsz
ps-mem() {
    local opts
    if [ "$(uname)" = "Darwin" ]; then
        opts='uid,pid,ppid,stime,time,%cpu,%mem,vsz,rss,comm' 
    else
        opts='euid,pid,ppid,stime,time,%cpu,%mem,vsz,rsz,comm'
    fi
    ps -eo $opts | sort -k 7 -n -s
}

