#!/bin/bash
# uskee.org
#

ROOT=`pwd`
UNAME=`uname`

echox() { 
    [ $# -gt 1 ] && b="\033[${1}m" && e="\033[00m" && shift
    [ $UNAME = "Darwin" ] && echo=echo || echo="echo -e"
    $echo "${b}$*${e}\n" 
}

usage()
{
    echox 34 "usage: $0 set|clear"
}

set_begin()
{
    rm -f ${ROOT}/shell/envall.sh
    touch ${ROOT}/shell/envall.sh
    chmod 750 ${ROOT}/shell/envall.sh
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
        [ ! -f $java ] && echox 33 "no avaiable java: $java" && return
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
    [ "#$had" != "#" ] && echox 32 "[WARN] Had been set before!" && return

    cat >> "$bash_file" << EOF
# ${label}
export ZTOOLS_ROOT=${ROOT}
[ -f \$ZTOOLS_ROOT/shell/envall.sh ] && source \$ZTOOLS_ROOT/shell/envall.sh
# ${label_end}
EOF
    echox 32 "[OK] Set successful and Should login again!"
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
    set_begin
    set_vim
    set_java
    set_ant
    set_android
    set_end
elif [ $opt = "clear" ]; then
    set_clear
else
    usage && exit 1
fi

exit 0
