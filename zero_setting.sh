#!/bin/bash
# uskee.org
#

ROOT=`pwd`

echox() { color=$1; shift; echo -e "\033[${color}m$*\033[00m"; echo; }

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
if [ -f ~/.vim/umark.sh ]; then
    source ~/.vim/umark.sh
fi

EOF
}

set_java()
{
    if [ "$osname" = "Darwin" ]; then
        return
    fi
    
    if [ -f "/usr/local/bin/java" ]; then
        java="/usr/local/bin/java"
    elif [ -f "/usr/bin/java" ]; then
        java="/usr/bin/java"
    else
        echox 33 "no avaiable java, pls install it"
        return
    fi

    while true; do
        if [ ! -e $java ]; then
            echox 33 "no avaiable java: $java"
            return
        fi
        if [ -h $java ]; then
            java=`readlink $java`
        else
            break;
        fi
    done
    java=${java%%jre\/bin\/java}
    java=${java%%bin\/java}
    java_home=$java

    label="For JAVA_HOME Setting"
    cat >> $ROOT/shell/envall.sh << EOF
# ${label}
if [ "#"\$JAVA_HOME = "#" ]; then
    export JAVA_HOME=${java_home}
fi

EOF
}

set_ant()
{
    if [ "$osname" = "Darwin" ]; then
        return
    fi

    label="For ANT_HOME Setting"
    cat >> $ROOT/shell/envall.sh << EOF
# ${label}
if [ "#"\$ANT_HOME = "#" ]; then
    export ANT_HOME=\$ZTOOLS_ROOT/dist/ant-1.9.2
    PATH=\$ANT_HOME/bin:\$PATH
fi

EOF
}

set_mvn()
{
    if [ "$osname" = "Darwin" ]; then
        return
    fi

    label="For M2_HOME Setting"
    cat >> $ROOT/shell/envall.sh << EOF
# ${label}
if [ "#"\$M2_HOME = "#" ]; then
    export M2_HOME=\$ZTOOLS_ROOT/dist/maven-3.2.1
    PATH=\$M2_HOME/bin:\$PATH
fi

EOF
}

set_end()
{
    had=""
    label="<-- For envall.sh Setting"
    label_end="End envall.sh Setting -->"
    if [ -f "$bash_file" ]; then
        had=`sed -n /"$label"/p "$bash_file"`
    fi
    if test -n "$had"; then
        echox 32 "[WARN] Had been set before!"
        return
    fi

    cat >> "$bash_file" << EOF
# ${label}
export ZTOOLS_ROOT=${ROOT}
if [ -f \$ZTOOLS_ROOT/shell/envall.sh ]; then
    source \$ZTOOLS_ROOT/shell/envall.sh
fi
# ${label_end}
EOF
    echox 32 "[OK] Set successful and Should login again!"
}

set_clear()
{
    label="<-- For envall.sh Setting"
    label_end="End envall.sh Setting -->"
    if [ -f "$bash_file" ]; then
        sed -in /"$label"/,/"$label_end"/d "$bash_file"
    fi
}



##
## entry point
##

if [ $# -ne 1 ]; then
    echox 34 "usage: $0 set|clear"
    exit 1
fi

osname=`uname`
if [  "$osname" = "Darwin" ]; then
    bash_file=~/.profile
else
    bash_file=~/.bashrc
fi

if [ $1 = "set" ]; then
    set_clear
    set_begin
    set_vim
    set_java
    set_ant
    set_mvn
    set_end
elif [ $1 = "clear" ]; then
    set_clear
else
    echox 34 "usage: $0 set|clear"
    exit 1
fi

exit 0
