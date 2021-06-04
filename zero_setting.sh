#!/bin/bash
# uskee.org
#


kRoot=`pwd`
kUname=`uname`
[[ "$kUname" =~ "MINGW" || "$kUname" =~ "mingw" ]] && kUname="MINGW"

kSudo="sudo"
kZpm="" # package manage tool

[ "$HOME" = "" ] && export HOME=~
kProfile=$HOME/.bashrc
kProfile2=$HOME/.zshrc

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


###================================

check_pkg() {
    [ $# -ne 1 ] && return 1
    which $1 2>/dev/null || return 1
    return 0
}

check_install() {
    local opts="t:b:p:f"
    local args=`getopt $opts $*`
    [ $? != 0 ] && return 1

    local tool bin pkg force
    set -- $args
    for i; do
        case "$i" in
            -t) tool=$2; shift; shift;;
            -b) bin=$2; shift; shift;;
            -p) pkg=$2; shift; shift;;
            -f) force="true"; shift;;
            --) shift; break;;
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
    printf "Installing '$pkg' by $(basename $tool) (y/n): " && read ret
    [ $ret = "y" ] && $tool install $pkg
    check_pkg $bin || return 1
    return 0
}

zpm_install() {
    check_install -t "$kZpm" $* || return 1
    return 0
}

prepare_zpm() {
    local msg zpm
    while true; do
        if [ "$kUname" = "Darwin" ]; then
            zpm=`which brew 2>/dev/null`
            [ "$zpm" = "" ] && zpm=`which port 2>/dev/null` && zpm="$kSudo $zpm"
            msg="Pls install 'macports' or 'homebrew'!"
        else
            # For redhat/fedora/centos/debian/ubuntu
            zpm=`which yum 2>/dev/null`
            [ "$zpm" = "" ] && zpm=`which aptitude 2>/dev/null`
            [ "$zpm" = "" ] && zpm=`which apt-get 2>/dev/null`
            [ "$zpm" != "" ] && zpm="$kSudo $zpm"
            msg="Pls install yum/apt/aptitude!"
        fi
        break
    done
    [ "$zpm" = "" ] && echoy "$msg" && return 1
    kZpm="$zpm"
    return 0
}


###================================

usage() 
{
    echog "usage: zero-set set|clear|prepare"
    echo
}

set_prepare() 
{
    prepare_zpm || return 1

    if [ "$kUname" = "Darwin" ]; then
        zpm_install -b bash-completion -f || return 1
        zpm_install -b coreutils -f # gls
        zpm_install -b dateutils -f # gdate
    fi

    zpm_install -b ctags -f || return 1
    zpm_install -b cscope || return 1
    #zpm_install -b cmake || return 1
    #zpm_install -b ant || return 1
    zpm_install -b vim -f || return 1
    return 0
}

set_begin()
{
    rm -f ${kRoot}/shell/envall.sh
    touch ${kRoot}/shell/envall.sh
    chmod 750 ${kRoot}/shell/envall.sh
}

set_env() 
{
    local zero=$HOME/.zero
    [ -e $zero ] && rm -rf $zero
    ln -sf $kRoot/shell/.zero $zero

    cat >> $kRoot/shell/envall.sh << EOF
# For ENV variables
[ "\$HOME" = "" ] && export HOME=~
_ZPATH="/usr/local/bin:/usr/local/sbin"
_ZPATH="\$_ZPATH:\$HOME/.local/bin"

# For shell extending
[ -f "\$HOME/.zero/uinit.sh" ] && source "\$HOME/.zero/uinit.sh"

# For python virtualenv
#venv init 2>/dev/null 1>&2

EOF
}

set_vim()
{
    local ext=${RANDOM}.bak
    local list=".vim .vimrc"
    for rc in $list; do
        local vim=$HOME/$rc
        [ -h $vim ] && rm -f $vim
        [ -e $vim ] && mv -f $vim ${vim}.${ext}
        ln -sf $kRoot/shell/$rc $vim
    done
    
    local ret=`which dos2unix 2>/dev/null`
    [ "$ret" = "" ] && return

    if [ "$kUname" = "MINGW" ]; then
        dos2unix -f $HOME/.vimrc
        rm -f $HOME/.vim/plugin/taglist.vim
        find $HOME/.vim/ -name *.vim -exec dos2unix -f {} \;
    fi
}

set_java()
{
    local java_home
    if [ "$kUname" = "Darwin" ]; then
        [ ! -f "/usr/libexec/java_home" ] && return
        java_home=`/usr/libexec/java_home`
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

    cat >> $kRoot/shell/envall.sh << EOF
# For Java
[ "#\$JAVA_HOME" = "#" ] && export JAVA_HOME=${java_home}

EOF
}

set_android()
{
    cat >> $kRoot/shell/envall.sh << EOF
# For Android
[ "#\$ANDROID_SDK" = "#" ] && export ANDROID_SDK=\$ANDROID_HOME
[ "#\$ANDROID_SDK" != "#" ] && _ZPATH="\$_ZPATH:\$ANDROID_SDK/platform-tools:\$ANDROID_SDK/tools"

[ "#\$ANDROID_NDK" = "#" ] && export ANDROID_NDK=\$ANDROID_NDK_HOME
[ "#\$ANDROID_NDK" != "#" ] && _ZPATH="\$_ZPATH:\$ANDROID_NDK"

EOF
}

set_end()
{
    cat >> $kRoot/shell/envall.sh << EOF
# To export PATH
export PATH="\$_ZPATH:\$PATH"

EOF

    local had=""
    local label="ztools begin"
    local label_end="ztools end"
    [ -f "$kProfile" ] && had=`sed -n /"$label"/p "$kProfile"`
    [ "$had" != "" ] && echoy "Had been set before!" && return

    cat >> "$kProfile" << EOF
## ${label}
## Please ensure it at the last line
export ZTOOLS="${kRoot}"
export ZBASH="\$ZTOOLS/shell/envall.sh"
[ -f "\$ZBASH" ] && source "\$ZBASH"
## ${label_end}
EOF
    echog "Set successful and Should login again!"
    echo
}

set_bashrc()
{
    [ ! -f $kProfile ] && return 1

    # if exists ".bash_profile", bash will not load ".profile"
    local profile="$HOME/.bash_profile"
    [ -h "$profile" ] && rm -f $profile
    if [ ! -f "$profile" ]; then
        ln -sf $kProfile $profile
    else
        local label="zbash begin"
        local label_end="zbash end"
        sed -in /"$label"/,/"$label_end"/d "$profile"
        cat >> "$profile" << EOF
## ${label}
## Please ensure it at the last line
[ -f \$HOME/.bashrc ] && source \$HOME/.bashrc
## ${label_end}
EOF
    fi

    if [ ! -f "$kProfile2" ]; then
        ln -sf $kProfile $kProfile2
    fi
}

set_clear()
{
    local label="ztools begin"
    local label_end="ztools end"
    [ -f "$kProfile" ] && sed -in /"$label"/,/"$label_end"/d "$kProfile"
}



##
## entry point
##

[ $# -ne 1 ] && usage && exit 1 || opt=$1


if [ $opt = "set" ]; then
    set_clear
    set_begin
    set_env
    set_vim
    set_java
    set_android
    set_end
    set_bashrc
elif [ $opt = "prepare" ]; then
    set_prepare
elif [ $opt = "clear" ]; then
    set_clear
else
    usage && exit 1
fi

exit 0
