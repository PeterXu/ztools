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

    opt="-R --c++-kinds=+p --fields=+iaS --extra=+q --languages=c++,c,java"
    (cd -P $dst 2>/dev/null && ctags $opt $src 2>/dev/null;)

    opt="-R --C++-kinds=+p --fields=+iaS --extra=+q --languages=c++,c,java -n"
    (cd -P $dst 2>/dev/null && ctags $opt -f cppcomplete.tags $src;)
}

gen_clean()
{
    [ $# -eq 1 ] && rm -rf $1
}


################################

main() 
{
    # check
    local xroot=".xtags/"
    mkdir -p $xroot
    [ ! -d $xroot ] && echo "not found: $xroot" && exit 1
    [ $# -eq 1 ] && [ "$1" = "clean" ] && gen_clean $xroot && exit 0

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

main $*
exit 0
