#!/usr/bin/env bash
#


## ------------
## for bash map
_help_map() {
    local opt="set,get,del"
    [ $# -gt 0 ] && opt="$*"
    echo "usage:"
    [[ "$opt" =~ "set" ]] && echo "       mapset vname key value"
    [[ "$opt" =~ "get" ]] && echo "       mapget vname key"
    [[ "$opt" =~ "del" ]] && echo "       mapdel vname key"
    echo
    return 0
}
mapset() {
    [ $# -ne 3 ] && _help_map set && return 1
    local vname=`_make_vname "${1}_${2}"` || return 1
    eval "${vname}=\"${3}\""
}
mapget() {
    [ $# -ne 2 ] && _help_map get && return 1
    local vname=`_make_vname "${1}_${2}"` || return 1
    declare -p ${vname} 2>/dev/null 1>&2 || return 1
    eval "echo \${${vname}}"
}
mapdel() {
    [ $# -ne 2 ] && _help_map del && return 1
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


## ----------------
## print with color and ctrl
_print_color() {
    [ $# -lt 3 ] && return 1
    local b="\033[${1}${2}m"
    local e="\033[00m"
    shift; shift
    printf "${b}${*}${e}" 
    return 0
}
printx() {
    local background=0 color=0 ctrl=""
    while [ $# -ge 1 ]; do
        case "$1" in
            @background)        background=10; shift;;

            @black)             color=30; shift;;
            @r|@red)            color=31; shift;;
            @g|@green)          color=32; shift;;
            @y|@yellow)         color=33; shift;;
            @b|@blue)           color=34; shift;;
            @p|@purple)         color=35; shift;;
            @c|@cyan)           color=36; shift;;
            @white)             color=37; shift;;

            @bold)              ctrl=";1"; shift;;  
            @bright)            ctrl=";2"; shift;;  
            @uscore)            ctrl=";4"; shift;;  
            @blink)             ctrl=";5"; shift;;  
            @invert)            ctrl=";7"; shift;; 
            *)                  break;;
        esac
    done
    [ $color -gt 0 ] && color=$((color+background))
    [ $# -lt 1 ] && return 1
    _print_color "$color" "$ctrl" "$*"
}
printxln() { 
    printx $* "\n" 
}
_help_printx() {
    local prog="printx" color="cyan" ctrl="bold"
    echo "usage: "
    echo "  $prog [@opt] string"
    echo "      options:" 
    echo "          backgound"
    echo "          black|red[r]|green[g]|yellow[y]|blue[b]|purple[p]|cyan[c]|white"
    echo "          bold|bright|uscore|blink|invert"
    echo
    echo "e.g."
    echo "  $prog font is normal"
    echo "  $prog @$color font is $color"
    echo "  $prog @$color @$ctrl font is $color and $ctrl"
    echo "  $prog @background @$color backgroud is $color and font unchanged"
    echo "  $prog @background @$color @$ctrl backgroud is $color and font is $ctrl"
    echo
}

