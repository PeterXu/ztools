#!/bin/bash
# author: uskee.org
# date  : 2012/12/03
#
# prerequired tools:
#   (a) ctags for c/cpp
#   (b) cscope for c/cp
#   (c) jtags for java [option]
#


#=========================================
# config for c/c++ files
#=========================================


# for cscope 
gen_cs() 
{
    local src dst cs files

    [ $# -ne 2 ] && echo "[WARN] usage: gen_cs dst src" && return
    dst="$1" && src="$2"

    cs=`which cscope 2>/dev/null`
    [ "$cs" = "" ] && echo "[WARN] Pls install cscope!" && return

    > cscope.files
    for s in $src; do
        find $src -type f \
            -name "*.h" -o -name "*.c" \
            -o -name "*.cc" -o -name "*.cpp" \
            -o -name "*.java" \
            -o -name "*.m" -o -name "*.mm" >> cscope.files
    done
    cscope -bkq -i cscope.files 2>/dev/null

    files="cscope.files cscope.in.out cscope.out cscope.po.out "
    for csf in $files; do
        [ -f $csf ] && mv $csf $dst
    done
}


# for tags and cppcomplete
gen_ct()
{
    local src dst ct opt

    [ $# -ne 2 ] && echo "[WARN] usage: gen_ct dst src" && return
    dst="$1" && src="$2"

    ct=`which ctags 2>/dev/null`
    [ "$ct" = "" ] && echo "[WARN] Pls install ctags!" && return

    opt="$gopts"
    (cd -P $dst 2>/dev/null && ctags $opt $src 2>/dev/null;)

    opt="$gopts -n -f cppcomplete.tags"
    (cd -P $dst 2>/dev/null && ctags $opt $src;)
}


gen_clean()
{
    [ $# -eq 1 ] && rm -rf $1
}


# usage: main root path
gen_main() 
{
    # check
    [ $# -lt 2 ] && exit 1
    local xroot=$1 && shift
    mkdir -p $xroot
    [ ! -d $xroot ] && echo "[ERROR] not found: $xroot" && exit 1

    local cs_root=.
    local ct_root=..
    if [ $# -ge 1 ]; then
        cs_root="" && ct_root=""
        for f in $*; do
            [ ! -d "$f" ] && echo "not found: $f" && exit 1
            cs_root="$cs_root $f"
            [[ ! $f =~ ^/.* ]] && ct_root="$ct_root ../$f"
        done
    fi

    # generate
    gen_cs "$xroot" "$cs_root" 
    gen_ct "$xroot" "$ct_root" 
}



#======================
# entry of this script
#======================

usage() {
    echo "usage: $gprog -c -a -e pats -l langs srcpath"
    echo "      -c: clean previous tags"
    echo "      -a: append mode, disabled default"
    echo "      -e pats: Add patterns to a list of excluded files and directories, e.g. 'file1,dir2'."
    echo "      -l langs: 'c++,c,java' default"
    exit 1
}

parse() {
    local args langs excludes OLD_IFS

    args=`getopt hcae:l: $*`
    [ $? != 0 ] && usage

    langs="c++,c,java"
    set -- $args
    for c; do
        case "$c" in
            -h) shift; usage;;
            -c) 
                gen_clean $groot; shift; exit 0
                ;;
            -a) 
                gopts="$gopts -a"; shift;;
            -e) 
                OLD_IFS="$IFS" && IFS=","
                excludes=($2) && IFS="$OLD_IFS"
                for pat in ${excludes[@]}; do 
                    gopts="$gopts --exclude=\"$pat\""
                done
                shift; shift;;
            -l) 
                OLD_IFS="$IFS" && IFS=","
                langs=($2) && IFS="$OLD_IFS"
                for lang in ${langs[@]}; do 
                    [ $lang = "c++" -o $lang = "java" -o $lang = "c" ] || usage 
                done
                langs="$2"; shift; shift;;
            --) shift; break;;
        esac
    done

    [ $# -ge 1 ] && gpath="$*" || gpath="."
    gopts="-R --languages=$langs --c++-kinds=+p --fields=+iaS --extra=+q $gopts"
}


gprog=$0
groot=".xtags/"
gpath=.

parse $*
gen_main $groot $gpath

exit 0
