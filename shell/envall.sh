# For Vim Setting
alias srcin="~/.vim/src_insight.sh"
if [ -f ~/.vim/umark.sh ]; then
    source ~/.vim/umark.sh
fi

# For JAVA_HOME Setting
export JAVA_HOME=/usr/java/default/

# For ANT_HOME Setting
if [ ! -n "$ANT_HOME" ]; then
    export ANT_HOME=$ZTOOLS_ROOT/dist/ant-1.9.2
    PATH=$PATH:$ANT_HOME/bin
fi

