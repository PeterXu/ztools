#!/bin/bash
# uskee.org
#


ROOT=`pwd`
UNAME=`uname`
zpm="" # package manage tool

[ "$HOME" = "" ] && export HOME=~

echox() { 
    local b t e
    [ $# -le 2 ] && return
    b="\033[${1}m" && shift
    t=${1} && shift 
    e="\033[00m"
    printf "${b}${t}${e} $*\n" 
}
echor() { echox 31 "[ERRO]" "$*"; }
echog() { echox 32 "[INFO]" "$*"; }
echoy() { echox 33 "[WARN]" "$*"; }
echob() { echox 34 "[INFO]" "$*"; }

echop() {
    echo
    echob "[*] Process: $*"
    eval "$*"
    echog "[*] Return: $?"
    echo
}



###================================

check_pkg() {
    [ $# -ne 1 ] && return 1
    which $1 2>/dev/null || return 1
    return 0
}

check_install() {
    local opts args
    opts="t:b:p:f"
    args=`getopt $opts $*`
    [ $? != 0 ] && return 1

    local force tool bin pkg
    force=""
    set -- $args
    for i; do
        case "$i" in
            -t)
                tool=$2; shift;
                shift;;
            -b)
                bin=$2; shift;
                shift;;
            -p)
                pkg=$2; shift;
                shift;;
            -f)
                force="true";
                shift;;
            --)
                shift; break;;
        esac
    done

    [ "$tool" = "" -o "$bin" = "" ] && return 1
    [ "$pkg" = "" ] && pkg="$bin"

    if [ "$force" != "" ]; then
        echoy "===== FORCE INSTALL: $tool install $pkg ====="
    else
        check_pkg $bin && return 0
        echoy "===== FRESH INSTALL: $tool install $pkg ====="
    fi

    local ret
    printf "Installing '$pkg' by $zpm (y/n): " && read ret
    [ $ret = "y" ] && $tool install $pkg
    check_pkg $bin || return 1
    return 0
}

zpm_install() {
    check_install -t "$zpm" $* || return 1
    return 0
}

prepare_zpm() {
    local msg
    if [ "$UNAME" = "Darwin" ]; then
        zpm=`which brew 2>/dev/null`
        [ "$zpm" != "" ] && return 0
        zpm=`which port 2>/dev/null`
        [ "$zpm" != "" ] && zpm="sudo $zpm"
        msg="Pls install 'macports' or 'homebrew'!"
    else
        # For redhat/fedora/centos/debian/ubuntu
        zpm=`which yum 2>/dev/null`
        [ "$zpm" = "" ] && zpm=`which aptitude 2>/dev/null`
        [ "$zpm" = "" ] && zpm=`which apt-get 2>/dev/null`
        [ "$zpm" != "" ] && zpm="sudo $zpm"
        msg="Pls install yum/apt/aptitude!"
    fi
    [ "$zpm" = "" ] && echoy "$msg" && return 1
    return 0
}



###================================

usage() 
{
    echog "usage: $0 set|clear|prepare"
}

set_prepare() 
{
    prepare_zpm || return 1

    zpm_install -b ctags -f || return 1
    zpm_install -b cscope || return 1
    zpm_install -b cmake || return 1
    zpm_install -b ant || return 1
    return 0
}

set_begin()
{
    rm -f ${ROOT}/shell/envall.sh
    touch ${ROOT}/shell/envall.sh
    chmod 750 ${ROOT}/shell/envall.sh
}

set_env() 
{
    local label
    label="For Env Setting"
    cat >> $ROOT/shell/envall.sh << EOF
# ${label}
[ \`uname\` = "Darwin" ] && alias ls='ls -G'
which gls 2>/dev/null 1>&2 && alias ls='gls --color=auto'
alias ll='ls -l'
[ \`uname\` != "Darwin" ] && alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias cls='clear'
alias grep='grep --color=auto'
[ -f $HOME/.vim/umark.sh ] && source $HOME/.vim/umark.sh
[ -f $HOME/.vim/git-completion.bash ] && source $HOME/.vim/git-completion.bash

EOF
}

set_vim()
{
    local vim=$HOME/.vim
    [ -e $vim ] && rm -rf $vim
    ln -sf $ROOT/shell/.vim $vim

    local vimrc=$HOME/.vimrc
    [ -e $vimrc ] && rm -rf $vimrc
    ln -sf $ROOT/shell/.vimrc $vimrc

    local label="For Vim Setting"
    cat >> $ROOT/shell/envall.sh << EOF
# ${label}
alias srcin="bash $HOME/.vim/src_insight.sh"

EOF
}

set_java()
{
    if [ "$UNAME" = "Darwin" ]; then
        [ ! -f "/usr/libexec/java_home" ] && return
        local java_home=`/usr/libexec/java_home`
    else
        local java=`which java 2>/dev/null`
        while true; do
            [ "$java" = "" -o ! -f "$java" ] && return
            [ -h $java ] && java=`readlink $java` || break
        done
        java=${java%%jre\/bin\/java}
        java=${java%%bin\/java}
        java_home=$java
    fi

    local label="For JAVA_HOME Setting"
    cat >> $ROOT/shell/envall.sh << EOF
# ${label}
[ "#\$JAVA_HOME" = "#" ] && export JAVA_HOME=${java_home}

EOF
}

set_android()
{
    local label="For ANDROID_HOME and ANDROID_NDK_HOME Setting"
    cat >> $ROOT/shell/envall.sh << EOF
# ${label}
[ "#\$ANDROID_HOME" != "#" ] && PATH=\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/tools:\$PATH && export ANDROID_HOME
[ "#\$ANDROID_NDK_HOME" != "#" ] && PATH=\$ANDROID_NDK_HOME:\$PATH && export ANDROID_NDK_HOME
[ "#\$ANDROID_NDK_HOME" != "#" ] && export ANDROID_NDK=\$ANDROID_NDK_HOME

EOF
}

set_end()
{
    local had=""
    local label="ztools begin"
    local label_end="ztools end"
    [ -f "$bash_file" ] && had=`sed -n /"$label"/p "$bash_file"`
    [ "$had" != "" ] && echoy "Had been set before!" && return

    cat >> "$bash_file" << EOF
## ${label}
## Please ensure it at the last line
export ZTOOLS=${ROOT}
[ -f \$ZTOOLS/shell/envall.sh ] && source \$ZTOOLS/shell/envall.sh
## ${label_end}
EOF
    echog "Set successful and Should login again!"
}

set_clear()
{
    local label="ztools begin"
    local label_end="ztools end"
    [ -f "$bash_file" ] && sed -in /"$label"/,/"$label_end"/d "$bash_file"
}



##
## entry point
##

[ $# -ne 1 ] && usage && exit 1 || opt=$1

bash_file=$HOME/.bash_profile
if [ ! -f $bash_file ]; then
    [ "$UNAME" = "Darwin" ] && bash_file=$HOME/.profile || bash_file=$HOME/.bashrc
fi

if [ $opt = "set" ]; then
    set_clear
    set_begin
    set_env
    set_vim
    set_java
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
