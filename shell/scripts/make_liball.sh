#!/bin/bash
# author: peterxu
#

## build config
ROOT=`pwd`/..
HOST=`uname`

echox() { 
    [ $# -gt 1 ] && b="\033[${1}m" && e="\033[00m" && shift
    [ $HOST = "Darwin" ] && echo=echo || echo="echo -e"
    $echo "${b}$*${e}" 
}
echor() { echox 31 "$*"; }
echog() { echox 32 "$*"; }
echoy() { echox 33 "$*"; }
echob() { echox 34 "$*"; }
check_err() {
    [ $? != 0 ] && echor "[*] Error and exit!!!, reason=$1" && exit 1
}

make_archive () {
    target=$1
    echog "[-] Generating archive lib$target.a ..."
    if [ $TARGET = "UNIX" ] || [ $TARGET = "ANDROID" ]; then
        rm -rf tmpobj; mkdir -p tmpobj; cd tmpobj
        for lib in $thelibs; do
            lib=../$lib
            if [ ! -e $lib ]; then
                echor "Can not find $lib!"; continue
            fi
            #echo "Processing $lib ..."
            $AR t $lib | xargs $AR qc lib$target.a
        done
        echo "Adding symbol table to archive."
        $AR sv lib$target.a
        mv lib$target.a ../
        cd -
        rm -rf tmpobj
    elif [ $TARGET = "IOS" ]; then
        libtool -static -arch_only armv7 -o lib$target.a ${thelibs[@]:0}
    elif [ $TARGET = "IOS-SIM" ]; then
        libtool -static -arch_only i386 -o lib$target.a ${thelibs[@]:0}
    elif [ $TARGET = "MAC" ]; then
        libtool -static -arch_only x86_64 -o lib$target.a ${thelibs[@]:0}
    fi
}


make_so () {
    target=$1
    echog "[-] Generate shared lib$target.so ..."
    if [ $TARGET = "UNIX" ] || [ $TARGET = "ANDROID" ]; then
        $CC -shared -o lib$target.so -Wl,-whole-archive $thelibs -Wl,-no-whole-archive $ldflags
    elif [ $TARGET = "MAC" ]; then
        libtool -dynamic -arch_only x86_64 -o lib$target.so ${thelibs[@]:0} $ldflags
    fi
}

usage() {
    echor "usage: $0 IOS|IOS-SIM|ANDROID target libdir1 [libdir2 ...]"
}

main() {
    [ $# -le 2 ] && usage && return

    TARGET=$1 && shift
    [ "$TARGET" != "IOS" -a "$TARGET" != "IOS-SIM" -a "$TARGET" != "ANDROID" -a "$TARGET" != "UNIX" ] && usage && return

    target=$1 && shift
    thelibs=""
    for dir in $*; do
        thelibs="$thelibs `find $dir -name "lib*.a" -print`"
    done

    # for static lib
    rm -f lib$target.a
    make_archive $target 2>/dev/null
    check_err "fail to gen archive .a"
    cp -f lib$target.a /tmp/
}

main $*
exit 0
