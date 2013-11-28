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
alias srcin="~/.vim/src_insight.sh"
if [ -f ~/.vim/umark.sh ]; then
    source ~/.vim/umark.sh
fi

EOF
}

set_java()
{
    jver=`java -version >/tmp/err.log 2>&1`
    if [ $? -ne 0 ]; then
        echox 33 "no avaiable java, pls install it"
        exit 1
    fi

	label="For JAVA_HOME Setting"
    cat >> $ROOT/shell/envall.sh << EOF
# ${label}
export JAVA_HOME=/usr/java/default/

EOF
}

set_ant()
{
	label="For ANT_HOME Setting"
    cat >> $ROOT/shell/envall.sh << EOF
# ${label}
if [ ! -n "\$ANT_HOME" ]; then
    export ANT_HOME=\$ZTOOLS_ROOT/dist/ant-1.9.2
    PATH=\$PATH:\$ANT_HOME/bin
fi

EOF
}

set_end()
{
	had=""
	label="<-- For envall.sh Setting"
	label_end="End envall.sh Setting -->"
	if [ -f ~/.bashrc ]; then
		had=`sed -n /"$label"/p ~/.bashrc`
	fi
	if test -n "$had"; then
        echox 32 "[WARN] Had been set before!"
        return
    fi

    cat >> ~/.bashrc << EOF
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
	if [ -f ~/.bashrc ]; then
        sed -i /"$label"/,/"$label_end"/d ~/.bashrc
    fi
}



##
## entry point
##

if [ $# -ne 1 ]; then
    echox 34 "usage: $0 set|clear"
    exit 1
fi

if [ $1 = "set" ]; then
    set_clear
    set_begin
    set_vim
    set_java
    set_ant
    set_end
elif [ $1 = "clear" ]; then
    set_clear
else
    echox 34 "usage: $0 set|clear"
    exit 1
fi

exit 0
