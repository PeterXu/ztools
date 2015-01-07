#!/usr/bin/env bash
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
    [[ "$gtype" =~ "cscope" ]] && gen_cs "$xroot" "$cs_root" 
    [[ "$gtype" =~ "ctags" ]]  && gen_ct "$xroot" "$ct_root" 
}



#======================
# entry of this script
#======================

usage() {
    echo "usage: $gprog -h -c -t -s -a -e pats -l langs srcpath"
    echo "      -h: print help"
    echo "      -c: clean previous tags/cscope files"
    echo "      -t: only ctags, default ctags & cscope"
    echo "      -s: only cscope, default ctags & cscope"
    echo "      -a: append mode, default disabled"
    echo "      -e pats: exclude path for ctags, 'path1,path2'. default 'third_party,out'"
    echo "      -l langs: default 'c++,c,java'"
    exit 1
}

parse() {
    local args=`getopt hctsae:l: $*`
    [ $? != 0 ] && usage

    local langs="c++,c,java"
    local ntags="--exclude=third_party --exclude=out"

    set -- $args
    for c; do
        case "$c" in
            -h) shift; usage;;
            -c) gen_clean $groot; shift; exit 0;;
            -t) gtype="ctags"; shift;;
            -s) gtype="cscope"; shift;;
            -a) gopts="$gopts -a"; shift;;
            -e) 
                local OLD_IFS="$IFS" && IFS=","
                local excludes=($2) && IFS="$OLD_IFS"
                ntags=""
                for pat in ${excludes[@]}; do 
                    ntags="$ntags --exclude=\"$pat\""
                done
                shift; shift;;
            -l) 
                local OLD_IFS="$IFS" && IFS=","
                langs=($2) && IFS="$OLD_IFS"
                for lang in ${langs[@]}; do 
                    [ $lang = "c++" -o $lang = "java" -o $lang = "c" ] || usage 
                done
                langs="$2"; shift; shift;;
            --) shift; break;;
        esac
    done

    [ $# -ge 1 ] && gpath="$*" || gpath="."
    gopts="-R --languages=$langs --c++-kinds=+p --fields=+iaS --extra=+q $ntags $gopts"
}


gprog=$0
groot=".xtags/"
gpath=.
gtype="ctags,cscope"

parse $*
gen_main $groot $gpath

exit 0
