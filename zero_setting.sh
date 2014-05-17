#!/bin/bash
# uskee.org
#

ROOT=`pwd`
UNAME=`uname`

echox() { 
    [ $# -le 2 ] && return
    b="\033[${1}m" && shift
    t=${1} && shift 
    e="\033[00m"
    [ $UNAME = "Darwin" ] && echo=echo || echo="echo -e"
    $echo "${b}${t}${e} $*" 
}

echor() { echox 31 "[ERRO]" "$*"; echo; }
echog() { echox 32 "[INFO]" "$*"; echo; }
echoy() { echox 33 "[WARN]" "$*"; echo; }
echob() { echox 34 "[INFO]" "$*"; echo; }

usage()
{
    echog "usage: $0 set|clear|prepare"
}

set_begin()
{
    rm -f ${ROOT}/shell/envall.sh
    touch ${ROOT}/shell/envall.sh
    chmod 750 ${ROOT}/shell/envall.sh
}

install_pkg () {
    [ $# -ne 2 ] && return
    pkg=$1 && bin=$2 
    which $bin 2>/dev/null 1>&2
    [ $? -eq 0 ] && return
    echob "\nFor package of $pkg ..."
    printf "Installing '$pkg' (y/n): " && read ret
    if [ $ret = "y" ]; then 
        printf "Enter passwd(sudo) ..."
        sudo $pm install $pkg
        [ $? -eq 0 ] && echog "success!" || echor "fail!"
        echob
    fi
}

prepare_mac() {
    [ "$UNAME" != "Darwin" ] && return

    which port 2>/dev/null 1>&2
    if [ $? -ne 0 ]; then
        echob "Install 'port' from http://www.macports.org" && return
    fi

    pm=port
    install_pkg coreutils gls
    install_pkg npm npm
    install_pkg cmake cmake
}

prepare_nix() {
    [ "$UNAME" = "Darwin" ] && return

    # For redhat/fedora/centos/..
    which yum 2>/dev/null 1>&2
    [ $? -eq 0 ] && pm=yum

    # For debian/ubuntu
    which apt-get 2>/dev/null 1>&2
    [ $? -eq 0 ] && pm=apt-get
    which aptitude 2>/dev/null 1>&2
    [ $? -eq 0 ] && pm=aptitude

    [ "#$pm" = "#" ] && return
    install_pkg npm npm
    install_pkg cmake cmake
}

set_prepare() {
    [ "$UNAME" = "Darwin" ] && prepare_mac || prepare_nix
}

set_gnu() 
{
    [ "$UNAME" != "Darwin" ] && return

    gnubin=/opt/local/libexec/gnubin

    label="For Mac GNU Setting (coreutils)"
    cat >> $ROOT/shell/envall.sh << EOF
# ${label}
if [ -e ${gnubin} ]; then
    PATH=${gnubin}:\$PATH
    alias ls='ls --color'
    alias grep='grep --color'
fi

EOF
}

set_vim()
{
    (
    cd ~/
    [ -e .vimrc ] && rm -rf .vimrc
    [ -e .vim ] && rm -rf .vim
    ln -sf $ROOT/shell/.vimrc
    ln -sf $ROOT/shell/.vim
    )

    label="For Vim Setting"
    cat >> $ROOT/shell/envall.sh << EOF
# ${label}
alias srcin="sh ~/.vim/src_insight.sh"
[ -f ~/.vim/umark.sh ] && source ~/.vim/umark.sh

EOF
}

set_java()
{
    [ "$UNAME" = "Darwin" ] && return
    
    java=`which java 2>/dev/null`
    while true; do
        [ ! -f $java ] && echoy "no avaiable java: $java" && return
        [ -h $java ] && java=`readlink $java` || break
    done
    java=${java%%jre\/bin\/java}
    java=${java%%bin\/java}
    java_home=$java

    label="For JAVA_HOME Setting"
    cat >> $ROOT/shell/envall.sh << EOF
# ${label}
[ "#\$JAVA_HOME" = "#" ] && export JAVA_HOME=${java_home}

EOF
}

set_ant()
{
    label="For ANT_HOME Setting"
    cat >> $ROOT/shell/envall.sh << EOF
# ${label}
if [ "#\$ANT_HOME" = "#" ]; then
    export ANT_HOME=\$ZTOOLS_ROOT/dist/ant-1.9.2
    PATH=\$ANT_HOME/bin:\$PATH
fi

EOF
}

set_android()
{
    label="For ANDROID_HOME and ANDROID_NDK_HOME Setting"
    cat >> $ROOT/shell/envall.sh << EOF
# ${label}
[ "#\$ANDROID_HOME" != "#" ] && PATH=\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/tools:\$PATH
[ "#\$ANDROID_NDK_HOME" != "#" ] && PATH=\$ANDROID_NDK_HOME:\$PATH

EOF
}

set_end()
{
    had=""
    label="<-- For envall.sh Setting"
    label_end="End envall.sh Setting -->"
    [ -f "$bash_file" ] && had=`sed -n /"$label"/p "$bash_file"`
    [ "#$had" != "#" ] && echoy "Had been set before!" && return

    cat >> "$bash_file" << EOF
# ${label}
export ZTOOLS_ROOT=${ROOT}
[ -f \$ZTOOLS_ROOT/shell/envall.sh ] && source \$ZTOOLS_ROOT/shell/envall.sh
# ${label_end}
EOF
    echog "Set successful and Should login again!"
}

set_clear()
{
    label="<-- For envall.sh Setting"
    label_end="End envall.sh Setting -->"
    [ -f "$bash_file" ] && sed -in /"$label"/,/"$label_end"/d "$bash_file"
}



##
## entry point
##

[ $# -ne 1 ] && usage && exit 1 || opt=$1

[ "$UNAME" = "Darwin" ] && bash_file=~/.profile || bash_file=~/.bashrc

if [ $opt = "set" ]; then
    set_clear
    set_begin
    set_gnu
    set_vim
    set_java
    set_ant
    set_android
    set_end
elif [ $opt = "prepare" ]; then
    set_prepare
elif [ $opt = "clear" ]; then
    set_clear
else
    usage && exit 1
fi

exit 0
