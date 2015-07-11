#!/usr/bin/env bash
#

_make_vname() {
    [ $# -ne 1 ] && return 1
    local vname=`echo g_${1} | tr [:space:]- _`
    local vtrim=`echo $vname | tr -d [:alnum:]_`
    echo $vname | tr -d "$vtrim"
}

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

