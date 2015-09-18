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
    [ $# -eq 1 -a -d "$1" ] && rm -rf $1
}



#======================
# entry of this script
#======================

__help_srcin() {
    local prog="srcin"
    echo "usage: $prog [-h -c -t tool -s -a -e pats -l langs] srcpath"
    echo "      -h: print help"
    echo "      -c: clean previous tags/cscope files"
    echo "      -t: use which tool, default both ctags & cscope"
    echo "           - ctags: only ctags"
    echo "           - cscope: only cscope"
    echo "      -s: generate system tags(default /usr/include)"
    echo "      -a: append mode, default disabled"
    echo "      -e pats: exclude path for ctags, 'path1,path2'. default 'third_party,out'"
    echo "      -l langs: default 'c++,c,java'"
    echo
}

srcin() {
    local mask="0x0"
    local root=".xtags/"
    local opts=""
    local cbin="ctags,cscope"
    local langs="c++,c,java"
    local ntags="--exclude=third_party --exclude=out"

    local args=`getopt hct:sae:l: $*`
    if [ $? != 0 ]; then
        __help_srcin
        return 1
    fi

    set -- $args
    for c; do
        case "$c" in
            -h) __help_srcin; shift; return 1;;
            -c) # clean
                mask=$((mask|0x01))
                shift;;
            -t) # tool
                [ "$2" != "ctags" -a "$2" != "cscope" ] && __help_srcin
                cbin="$2"
                shift; shift;;
            -s) # system tags
                mask=$((mask|0x02))
                root="$HOME/.xtags" 
                cbin="ctags"
                shift;;
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
                    [ "$lang" = "c++" -o "$lang" = "java" -o "$lang" = "c" ] || __help_srcin 
                done

                langs="$2";
                if [ "$langs" = "" ]; then
                    __help_srcin;
                    return 1;
                fi
                shift; shift;;
            --) shift; break;;
        esac
    done
    opts="-R --languages=$langs --c++-kinds=+p --fields=+iaS --extra=+q $ntags $opts"

    # clean path
    local sbit=$((mask & 0x01))
    if [ $sbit -ne 0 ]; then
        _gen_clean $root
        return 0
    fi

    # source path
    local spath cs_root ct_root
    cs_root="" && ct_root=""
    sbit=$((mask & 0x02))
    if [ $sbit -ne 0 ]; then
        spath="/usr/include"
        ct_root="$spath"
    else
        if [ $# -lt 1 ]; then
            __help_srcin;
            return 1;
        fi

        spath="$*"
        if [ "$spath" = "." ]; then
            cs_root=. && ct_root=..
        else
            for f in $spath; do
                [ ! -d "$f" ] && echo "[WARN] not found: $f" && return 1
                cs_root="$cs_root $f"
                [[ ! $f =~ ^/.* ]] && ct_root="$ct_root ../$f"
            done
        fi
    fi

    # check root
    mkdir -p $root
    [ ! -d $root ] && echo "[ERROR] not found: $root" && return 1

    # generate
    [[ "$cbin" =~ "cscope" ]] && _gen_cs "$root" "$cs_root" 
    [[ "$cbin" =~ "ctags" ]]  && _gen_ct "$root" "$ct_root" "$opts"

    return 0
}

