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


# For the usage of cscope: _gen_cs dst src
_gen_cs() {
    local cs dst src csfile exts opts files
    cs=`which cscope 2>/dev/null` || return 1

    [ $# -ne 2 ] && return 1
    dst="$1" && src="$2"
    csfile="cscope.files"
    echo "" > $csfile

    echo "[INFO] To proc <$src> by $(basename $cs) ..."

    # for cscope
    exts="h c cc cpp java m mm"
    for e in $exts; do
        opts="$opts -name \"*.$e\""
    done
    for s in $src; do
        find $s -type f $opts >> $csfile
    done
    $cs -bkq -i $csfile 2>/dev/null

    # for generated files
    move=`which mv 2>/dev/null` || return 1
    files="cscope.files cscope.in.out cscope.out cscope.po.out "
    for csf in $files; do
        [ -f $csf ] && $move $csf $dst
    done

    return 0
}


# For the usage of tags & cppcomplete: _gen_ct dst src [opt]
_gen_ct() {
    local ct dst src opt opts
    ct=`which ctags 2>/dev/null` || return 1

    [ $# -lt 2 -a $# -gt 3 ] && return 1
    dst="$1" && src="$2"
    [ $# -eq 3 ] && opt="$3" || opt=""

    echo "[INFO] To proc <$src> by $(basename $ct) ..."

    # for tags
    opts="$opt"
    (cd -P $dst 2>/dev/null && $ct $opts $src 2>/dev/null;)

    # for cppcomplete
    opts="$opt -n -f cppcomplete.tags"
    (cd -P $dst 2>/dev/null && $ct $opts $src;)

    return 0
}


_gen_clean() {
    [ $# -eq 1 ] && rm -rf $1
}



#======================
# entry of this script
#======================

_gen_usage() {
    local prog="srcin"
    echo "usage: $prog -h -c -t -s -a -e pats -l langs srcpath"
    echo "      -h: print help"
    echo "      -c: clean previous tags/cscope files"
    echo "      -t: only ctags, default ctags & cscope"
    echo "      -s: only cscope, default ctags & cscope"
    echo "      -a: append mode, default disabled"
    echo "      -e pats: exclude path for ctags, 'path1,path2'. default 'third_party,out'"
    echo "      -l langs: default 'c++,c,java'"
}

srcin() {
    local root=".xtags/"
    mkdir -p $root
    [ ! -d $root ] && echo "[ERROR] not found: $root" && return 1

    local opts=""
    local cbin="ctags,cscope"
    local langs="c++,c,java"
    local ntags="--exclude=third_party --exclude=out"

    local args=`getopt hctsae:l: $*`
    if [ $? != 0 ]; then
        _gen_usage
        return 1
    fi

    set -- $args
    for c; do
        case "$c" in
            -h) _gen_usage; shift; return 1;;
            -c) _gen_clean $root; shift; return 0;;
            -t) cbin="ctags"; shift;;
            -s) cbin="cscope"; shift;;
            -a) opts="$opts -a"; shift;;
            -e) 
                local OLD_IFS="$IFS" && IFS=","
                local excludes=($2) && IFS="$OLD_IFS"

                ntags=""
                for pat in ${excludes[@]}; do 
                    [ "$pat" != "" ] && ntags="$ntags --exclude=\"$pat\""
                done
                shift; shift;;
            -l) 
                local OLD_IFS="$IFS" && IFS=","
                langs=($2) && IFS="$OLD_IFS"
                for lang in ${langs[@]}; do 
                    [ "$lang" = "c++" -o "$lang" = "java" -o "$lang" = "c" ] || _gen_usage 
                done

                langs="$2";
                if [ "$langs" = "" ]; then
                    _gen_usage;
                    return 1;
                fi
                shift; shift;;
            --) shift; break;;
        esac
    done
    opts="-R --languages=$langs --c++-kinds=+p --fields=+iaS --extra=+q $ntags $opts"

    # source path
    if [ $# -lt 1 ]; then
        _gen_usage;
        return 1;
    fi

    local path cs_root ct_root
    path="$*"
    if [ "$path" = "." ]; then
        cs_root=. && ct_root=..
    else
        cs_root="" && ct_root=""
        for f in $path; do
            [ ! -d "$f" ] && echo "[WARN] not found: $f" && return 1
            cs_root="$cs_root $f"
            [[ ! $f =~ ^/.* ]] && ct_root="$ct_root ../$f"
        done
    fi

    # generate
    [[ "$cbin" =~ "cscope" ]] && _gen_cs "$root" "$cs_root" 
    [[ "$cbin" =~ "ctags" ]]  && _gen_ct "$root" "$ct_root" "$opts"

    return 0
}

