#!/usr/bin/env bash
#

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

## ------------
## for bash map
__help_map() {
    local opt="set,get,del,key,unk"
    [ $# -gt 0 ] && opt="$*"
    echo "usage:"
    [[ "$opt" =~ "set" ]] && echo "       mapset vname key value"
    [[ "$opt" =~ "get" ]] && echo "       mapget vname key"
    [[ "$opt" =~ "del" ]] && echo "       mapdel vname key"
    [[ "$opt" =~ "key" ]] && echo "       mapkey vname"
    [[ "$opt" =~ "unk" ]] && echo "       mapunkey vname"
    echo
    return 0
}
_mapset() {
    [ $# -ne 3 ] && __help_map set && return 1
    local vname=`_make_vname "${1}_${2}"` || return 1
    eval "${vname}='${3}'"

    local vkeys=`_make_vname "${1}_keys"` || return 1
    local rkey=`_make_rname "${2}"` || return 1
    local rkeys=$(eval "echo \${${vkeys}}")
    eval "${vkeys}='${rkeys} ${rkey}'"
}
_mapget() {
    [ $# -ne 2 ] && __help_map get && return 1
    local vname=`_make_vname "${1}_${2}"` || return 1
    declare -p ${vname} 2>/dev/null 1>&2 || return 1
    eval "echo \"\${${vname}}\""
}
_mapdel() {
    [ $# -ne 2 ] && __help_map del && return 1
    local vname=`_make_vname "${1}_${2}"` || return 1
    eval "unset ${vname}"
}
_mapkey() {
    [ $# -ne 1 ] && __help_map key && return 1
    local vkeys=`_make_vname "${1}_keys"` || return 1
    eval "echo \${${vkeys}}"
}
_mapunkey() {
    [ $# -ne 1 ] && __help_map unk && return 1
    local vkeys=`_make_vname "${1}_keys"` || return 1
    eval "unset ${vkeys}"
}


## -------------
## ssh with tips
_sshx() {
    local opts=`cat $HOME/.ssh/config 2>/dev/null  | grep "Host " | awk '{print $2}'`
    _tablist "ssh" "$opts"
}
_scpx() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    if [ "${cur:0:2}" = "./" ]; then
        local opts
        if [ "${cur:(-1):1}" != "/" ]; then
            cur=`dirname "$cur"`
            cur="$cur/"
        fi
        for i in `ls "$cur"`; do
            local item="$cur$i"
            [ -d "$item" ] && item="$item/"
            opts="$opts $item"
        done
        _tablist2 "scp" "$opts"
    else
        local opts=`cat $HOME/.ssh/config 2>/dev/null  | grep "Host " | awk '{print $2}'`
        _tablist2 "scp" "$opts"
    fi
}

_rsyncx_backup() {
    [ $# -ne 2 ] && echo "usage: REMOTE_RSYNC="/usr/bin/rsync" REMOTE_SSH_PORT=22 rsyncx_backup src dst" && return
    local src="$1"
    local dst="$2"
    local port="${REMOTE_SSH_PORT}"
    local rrsync="${REMOTE_RSYNC}"
    [ "#$rrsync" = "#" ] && rrsync="rsync"
    #TODO: some version may not support these arguments, then should specify which version.
    local opts="-aNHAXx --protect-args --fileflags --force-change"
    if [ "#$port" = "#" ]; then
        echo "Connecting to remote :22"
        rsync $opts --rsync-path="$rrsync" "$src" "$dst"
    else
        echo "Connecting to remote :$port"
        rsync $opts --rsync-path="$rrsync" -e "ssh -p $port" "$src" "$dst"
    fi
}

_rsyncx() {
    [ $# -ne 2 ] && echo "usage: REMOTE_SSH_PORT=22 rsyncx src dst" && return
    local src="$1"
    local dst="$2"
    local port="${REMOTE_SSH_PORT}"

    local opts="-avP"
    if [ "#$port" = "#" ]; then
        echo "Connecting to remote :22"
        rsync $opts ${src} ${dst}
    else
        echo "Connecting to remote :$port"
        rsync $opts -e "ssh -p $port" "${src}" "${dst}"
    fi
}

_verify2fa() {
    cd ${DIR}/../../dist/common/
    python3 py2fa.py $*
}


## ---------------------
## for python virtualenv
__help_venv() {
    echo "usage: venv init|quit|renew [path]"
    echo "       renew  => create env if not exist, extra options by setting VENV_OPTS"
    echo "       init => enter python virtual env"
    echo "       quit => quit python virtual env"
    echo "       [path] => if none use ~/.vv, else path/.vv"
    echo
    return 0
}
_venv() {
    [ $# -ne 1 -a $# -ne 2 ] && __help_venv && return 1
    which virtualenv 2>/dev/null 1>&2 || return 1
    local action="$1" path="$2"

    local vv="$HOME/.vv"
    [ "$path" != "" ] && vv="$path/.vv"
    local todo=$vv/bin/activate
    case "$action" in
        renew)  rm -rf $vv
                virtualenv $VENV_OPTS $vv
                ;;
        init)   [ -f $todo ] && . $todo;;
        quit)   deactivate 2>/dev/null;;
        *)      __help_venv && return 1;;
    esac
}


## ------------------------
## ps -ef order by %mem/rsz
_ps_ef() {
    local nth str opt
    [ $# -lt 2 -o $# -gt 3 ] && return 1
    nth=$1 && str="$2"
    [ $# -eq 3 ] && opt=$3

    local opts
    if [ "$(uname)" = "Darwin" ]; then
        opts='uid,pid,ppid,stime,time,%cpu,%mem,vsz,rss,comm' 
    else
        opts='euid,pid,ppid,stime,time,%cpu,%mem,vsz,rsz,comm'
    fi
    ps -eo $opts | sort -k $nth -n -s $opt
    ps -eo $opts | grep "$str"
}


## ----------------
## print with color and ctrl
_print_color() {
    [ $# -lt 3 ] && return 1
    local b="\033[${1}${2}m"
    local e="\033[00m"
    shift; shift
    printf "${b}${*}${e}" 
    return 0
}
_printx() {
    local background=0 color=0 ctrl=""
    while [ $# -ge 1 ]; do
        case "$1" in
            @background)        background=10; shift;;

            @black)             color=30; shift;;
            @r|@red)            color=31; shift;;
            @g|@green)          color=32; shift;;
            @y|@yellow)         color=33; shift;;
            @b|@blue)           color=34; shift;;
            @p|@purple)         color=35; shift;;
            @c|@cyan)           color=36; shift;;
            @white)             color=37; shift;;

            @bold)              ctrl=";1"; shift;;  
            @bright)            ctrl=";2"; shift;;  
            @uscore)            ctrl=";4"; shift;;  
            @blink)             ctrl=";5"; shift;;  
            @invert)            ctrl=";7"; shift;; 
            *)                  break;;
        esac
    done
    [ $color -gt 0 ] && color=$((color+background))
    [ $# -lt 1 ] && return 1
    _print_color "$color" "$ctrl" "$*"
}
__help_printx() {
    local prog="printx" color="cyan" ctrl="bold"
    echo "usage: "
    echo "  $prog [@opt] string"
    echo "      options:" 
    echo "          backgound"
    echo "          black|red[r]|green[g]|yellow[y]|blue[b]|purple[p]|cyan[c]|white"
    echo "          bold|bright|uscore|blink|invert"
    echo
    echo "e.g."
    echo "  $prog font is normal"
    echo "  $prog @$color font is $color"
    echo "  $prog @$color @$ctrl font is $color and $ctrl"
    echo "  $prog @background @$color backgroud is $color and font unchanged"
    echo "  $prog @background @$color @$ctrl backgroud is $color and font is $ctrl"
    echo
}


##----------------
## for ini parser
__help_ini() {
    echo "usage:"
    echo "      ini_parse file: parse ini file"
    echo "      ini_secs file: print all sections"
    echo
    return 0
}
_ini_parse() {
    [ $# -ne 1 ] && __help_ini && return 1
    local ini=$1
    [ ! -f "$ini" ] && return 1

    local line secs xtype sec key val quit idx len
    while read line
    do
        xtype="none"; sec=""; key=""; val=""; quit=0
        for idx in `seq 0 ${#line}`
        do
            local ch=${line:$idx:1}
            case $ch in
                "#" | ";") xtype="comm"; quit=1;;
                "[") [ $xtype = "none" ] && xtype="sec0";;
                "]") [ $xtype = "sec1" ] && xtype="sec2";;
                "=") [ $xtype = "item0" ] && xtype="item1";;
                *);;
            esac
            [ $quit -ne 0 ] && break
            case $xtype in
                "none") xtype="item0"; key="$key$ch";;
                "sec1") sec="$sec$ch";;  # sec
                "sec0") xtype="sec1";;   # '['
                "item0") key="$key$ch";; # key
                "item2") val="$val$ch";; # val
                "item1") xtype="item2";; # '='
                *) ;;
            esac
        done

        sec=`echo "$sec" | sed 's/^[ \t]*//' | sed 's/[ \t]*$//'`
        key=`echo "$key" | sed 's/^[ \t]*//' | sed 's/[ \t]*$//'`
        val=`echo "$val" | sed 's/^[ \t]*//' | sed 's/[ \t]*$//'`
        [ "$sec" != "" ] && secs=(${secs[@]} $sec) && _mapunkey "$sec"

        len=${#secs[@]}
        [ $len -eq 0 ] && continue

        if [ "$key" != "" -a "$val" != "" ]; then
            _mapset "${secs[len-1]}" "$key" "$val"
        elif [ "$key" != "" ]; then
            _mapdel "${secs[len-1]}" "$key"
        fi
    done < $ini

    local vsecs=`_make_vname "${ini}_secs"` || return 1
    eval "${vsecs}='${secs[@]}'"
    return 0
}
_ini_secs() {
    [ $# -ne 1 ] && __help_ini && return 1
    local vsecs=`_make_vname "${1}_secs"` || return 1
    eval "echo \${${vsecs}}"
}


## ------------------------
## install YouCompleteMe plugin
_ycm_config() {
    [ $# -ne 1 ] && __help_ycm config && return 1

    local todo="$1"
    local vimdir=$HOME/.vim
    local workdir=$vimdir/bundle
    local ycmconf=$workdir/config.vim
    if [ "$todo" = "clean" ]; then
        rm -f $ycmconf
        return 0
    fi

    local valid=0
    local steps=""
    local actions="vundle ycm clang install"
    for item in $actions; do
        [ "$item" = "$todo" ] && valid=1
        steps="$steps -> $item"
    done

    [ $valid -ne 1 ] && __help_ycm config && return 1

    _printx @green "[INFO] Process <$todo> [$steps] ...\n"

    # check vundle
    if [ "$todo" = "vundle" ]; then
        local vundle=$workdir/Vundle.vim
        mkdir -p $workdir
        if [ ! -d $vundle ]; then
            local uri="https://github.com/VundleVim/Vundle.vim.git"
            git clone $uri $vundle
        fi

        if [ ! -d $vundle ]; then
          _printx @red "[ERROR] Fail to clone <$uri>\n"
          return 1
        fi
        return 0
    fi

    # check ycm
    if [ "$todo" = "ycm" ]; then
        local ycmdir=$workdir/YouCompleteMe
        mkdir -p $workdir
        if [ ! -d $ycmdir ]; then
            local tmpdir=${ycmdir}.tmp
            local uri="https://github.com/Valloric/YouCompleteMe.git"
            (
            [ ! -d $tmpdir ] && git clone --recursive $uri $tmpdir
            cd $tmpdir || exit 1 
            git submodule update --init --recursive || exit 1
            )
            [ -d $tmpdir ] && mv $tmpdir $ycmdir
        fi

        if [ ! -d $ycmdir ]; then
          _printx @red "[ERROR] Fail to clone $uri\n"
          return 1
        fi
        return 0
    fi

    if [ "$todo" = "clang" ]; then
        local ycmdir=$workdir/YouCompleteMe
        if [ ! -d $ycmdir ]; then 
          _printx @yellow "[WARN] No repo <YouCompleteMe> and pls run <ycm-config ycm> at first\n"
          return 1
        fi

        (
        cd $ycmdir || exit 1 
        chmod +x install.sh
        ./install.sh --clang-completer || exit 1
        ) || return 1
        return 0
    fi

    # config ycm
    if [ "$todo" = "install" ]; then
        # check vimrc whether it is from ztools?
        [ ! -f $vimdir/vimrc.vim ] && return 1

        rm -f $ycmconf
        local ycm="\$HOME/.vim/misc/.ycm_extra_conf.py"
        cat > $ycmconf << EOF
func! YcmInit()
    set nocompatible              " be iMproved, required
    filetype off                  " required
    set rtp+=\$HOME/.vim/bundle/Vundle.vim
    call vundle#begin()
    Plugin 'VundleVim/Vundle.vim'   " required
    Plugin 'Valloric/YouCompleteMe'
    call vundle#end()            " required
    filetype plugin indent on    " required

    " GoTo/GoToInclude/GoToDeclaration/GoToDefinition
    nnoremap <leader>jd :YcmCompleter GoToDefinitionElseDeclaration<CR>
    nnoremap <leader>ff :YcmForceCompileAndDiagnostics<CR>
    nnoremap <leader>er :YcmDiags<CR>

    let g:ycm_global_ycm_extra_conf = expand('$ycm')
    " Do not ask when starting vim
    let g:ycm_confirm_extra_conf = 0
    " Disable left warning dialog
    let g:ycm_show_diagnostics_ui = 0
    " Completion Tips
    let g:ycm_key_invoke_completion = '<C-c>'
endfunc

func! YcmRun(arg)
    if a:arg == "help" || a:arg == ""
        echo "\n[Usage]:\n"
            \ . "  <C-O>:           jump back\n"
            \ . "  <C-I>:           jump forward\n"
            \ . "  <C-c>:           invoke completion\n"
            \ . "  cc + jd:         goto definition else declaration(jump)\n"
            \ . "  cc + ff:         force compile and diagnostics(debug)\n"
            \ . "  cc + er:         show errors and warnings(show)\n"
            \ . "  <S-:> + cmd:     Ycm help|jump|debug|show\n"
            \ . "\n"
    elseif a:arg == "jump"
        YcmCompleter GoToDefinitionElseDeclaration
    elseif a:arg == "debug"
        YcmForceCompileAndDiagnostics
    elseif a:arg == "show"
        YcmDiags
    endif
endfunc

command! -nargs=* Ycm call YcmRun('<args>')
call YcmInit()

EOF
    fi
}
_ycm_here() {
    [ $# -ne 1 ] && __help_ycm here && return 1

    local todo="$1"
    local ycm="$HOME/.vim/misc/.ycm_extra_conf.py"
    local dst="./.ycm_extra_conf.py"
    if [ "$todo" = "cpp" ]; then
        cp -f "$ycm" $dst
    elif [ "$todo" = "c99" ]; then
        if cp -f "$ycm" $dst; then
            sed -i "s/^'-std=c++11',/'-std=c99',/" $dst
            sed -i "s/^'c++',/'c',/" $dst
        fi
    elif [ "$todo" = "clean" ]; then
        rm -f $dst ${dst}c
    else
        __help_ycm here
    fi
}
__help_ycm() {
    local opt="config,here"
    [ $# -gt 0 ] && opt="$*"
    echo "usage:"
    [[ "$opt" =~ "config" ]]    && echo "       ycm-config vundle|ycm|clang|install|clean"
    [[ "$opt" =~ "here" ]]      && echo "       ycm-here cpp|c99|clean"
    echo
}

##-------------
## for vim-go and gocode
_govim_config() {
    [ $# -ne 1 ] && __help_govim && return 1
    local todo="$1"
    local label="govim begin"
    local label_end="govim end"

    local vimdir=$HOME/.vim
    local workdir=$vimdir/bundle
    local goconf=$workdir/config.vim
    [ -f "$goconf" ] && sed -in /"$label"/,/"$label_end"/d "$goconf"
    if [ "$todo" = "clean" ]; then
        return 0
    fi

    which go 2>/dev/null 1>&2 || return 1
    go get -u github.com/nsf/gocode

    local vimgo=$workdir/vim-go
    mkdir -p $workdir
    if [ ! -d $vimgo ]; then
        local uri="https://github.com/fatih/vim-go.git"
        git clone $uri $vimgo
    fi

    cat >> $goconf << EOF
" $label
func! GoInit()
    call vundle#begin()
    set rtp+=\$HOME/.vim/bundle/vim-go
    Plugin 'fatih/vim-go'
    " go get -u github.com/nsf/gocode
    Plugin 'nsf/gocode'
    call vundle#end()            " required
    filetype plugin indent on    " required
endfunc
call GoInit()
" $label_end
EOF
}
__help_govim() {
    echo "usage: govim config|clean"
    echo
}


##--------------
## For pip
_set_pip() {
    local pip="$HOME/.pip"
    mkdir -p "$pip" || return 1
    rm -f $pip/pip.conf
    cat > $pip/pip.conf << EOF
[install]
install-option=--prefix=~/.local

EOF
}


##-------------
## For linux FIN_WAIT1
_reset_fin_wait1() {
    if [ "$(uname)" != "Linux" ]; then
        echo "It is only supported in Linux!"
        return
    fi

    if [ "$(whoami)" != "root" ]; then
        echo "Please switch from $(whoami) to root at frist!"
        return
    fi

    # Note: /proc/sys/net/ipv4/tcp_fin_timeout is for FIN-WAIT-2.
    local oldval=$(cat /proc/sys/net/ipv4/tcp_max_orphans)

    # set the tcp_max_orphans to 0 temporarily
    echo 0 > /proc/sys/net/ipv4/tcp_max_orphans

    # watch /var/log/messages
    # it will split out "kernel: TCP: too many of orphaned sockets"
    # it won't take long for the connections to be killed

    # restore the value of tcp_max_orphans whatever it was before. 
    echo $oldval > /proc/sys/net/ipv4/tcp_max_orphans
}

##-----------------
## For linux coredump
_set_coredump() {
    if [ "$(uname)" != "Linux" ]; then
        echo "It is only supported in Linux!"
        return
    fi

    if [ "$(id -u)" != "0" ]; then
        echo "Please run as root or sudo!"
        exit -1
    fi

    echo "[Old Settings]:"
    echo "  pattern:" $(cat /proc/sys/kernel/core_pattern)
    echo "  core_uses_pid:" $(cat /proc/sys/kernel/core_uses_pid)
    echo

    echo "[New Settings]:"
    #set the path of core file with permission
    # %s: which signal, %t: time
    echo "/tmp/core-%s-%t" > /proc/sys/kernel/core_pattern
    echo "  pattern:" $(cat /proc/sys/kernel/core_pattern)
    #set suffix of the core file name
    echo "1" > /proc/sys/kernel/core_uses_pid
    echo "  core_uses_pid:" $(cat /proc/sys/kernel/core_uses_pid)
    echo
}

##-------------
## For linux 
_show_tcp_qos() {
    if [ "$(uname)" != "Linux" ]; then
        echo "It is only supported in Linux!"
        return
    fi

    echo "Default TCP QoS:"
    echo "  net.core.default_qdisc = pfifo_fast"
    echo "  net.ipv4.tcp_congestion_control = cubic"
    echo
    echo "Current TCP QoS:"
    echo "  $(sysctl net.core.default_qdisc)"
    echo "  $(sysctl net.ipv4.tcp_congestion_control)"
    echo
    echo "Set BBR TCP QoS (/etc/sysctl.conf, kernel may need to upgrade!):"
    echo "  net.core.default_qdisc = fq"
    echo "  net.ipv4.tcp_congestion_control = bbr"
    echo
}

##-------------
## For linux user/group
_show_user_group() {
    echo "The Operations Of User and Group:"
    echo "  User Tools:                 useradd(adduser)|usermod|userdel"
    echo "  Group Tools:                groupadd|groupmod|groupdel"
    echo "  Add USER to GROUP:          gpasswd -a user group"
    echo "  Remove USER from GROUP:     gpasswd -d user group"
    echo "  Append GROUP to USER:       usermod -aG group user"
    echo "  Reset GROUPs to USER:       usermod -G group1[,group2..] user"
    echo
}

### init misc shell
__init_misc() {
    alias mapget="_mapget"
    alias mapset="_mapset"
    alias mapdel="_mapdel"
    alias mapkey="_mapkey"
    alias mapunkey="_mapunkey"

    alias venv="_venv"
    alias printx="_printx"
    alias ini-parse="_ini_parse"
    alias ini-secs="_ini_secs"

    alias ps-mem="_ps_ef 9 %MEM"
    alias ps-cpu="_ps_ef 6 %CPU"
    alias ps-pid="_ps_ef 2 ' PID'"
    alias ps-time="_ps_ef 4 ' TIME'"
    alias ps-stime="_ps_ef 5 STIME"
    alias psr-stime="_ps_ef 5 STIME -r"
    alias psr-pid="_ps_ef 2 ' PID' -r"

    alias ycm-config="_ycm_config"
    alias ycm-here="_ycm_here"
    alias govim="_govim_config"
    alias set-pip="_set_pip"
    alias reset-fin-wait1="_reset_fin_wait1"
    alias set-coredump="_set_coredump"
    alias show-user-group="_show_user_group"
    alias show-tcp-qos="_show_tcp_qos"

    alias rsyncx="_rsyncx"
    alias rsyncx-backup="_rsyncx_backup"
    _completex _sshx ssh
    _completex _scpx scp

    alias verify2fa="_verify2fa"
}

