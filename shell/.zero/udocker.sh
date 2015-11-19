# Some useful commands to use docker.
# Author: yeasy@github
# Created:2014-09-25
#
# Update: peter@uskee.org
# Modified: 2015/09/01

kUname=$(uname)
[[ "$kUname" =~ "MINGW" || "$kUname" =~ "mingw" ]] && kUname="MINGW"
#sudo usermod -aG docker username
[ "$kUname" = "MINGW" ] && kPty="winpty" || kSudo="sudo"


#the implementation refs from https://github.com/jpetazzo/nsenter/blob/master/docker-enter
_docker_enter() {
    #if [ -e $(dirname "$0")/nsenter ]; then
    #Change for centos bash running
    if [ -e $(dirname '$0')/nsenter ]; then
        # with boot2docker, nsenter is not in the PATH but it is in the same folder
        NSENTER=$(dirname "$0")/nsenter
    else
        # if nsenter has already been installed with path notified, here will be clarified
        NSENTER=$(which nsenter)
        #NSENTER=nsenter
    fi
    [ -z "$NSENTER" ] && echo "WARN Cannot find nsenter" && return

    if [ -z "$1" ]; then
        echo "Usage: `basename "$0"` CONTAINER [COMMAND [ARG]...]"
        echo ""
        echo "Enters the Docker CONTAINER and executes the specified COMMAND."
        echo "If COMMAND is not specified, runs an interactive shell in CONTAINER."
    else
        PID=$(docker inspect --format "{{.State.Pid}}" "$1")
        if [ -z "$PID" ]; then
            echo "WARN Cannot find the given container"
            return
        fi
        shift

        OPTS="--target $PID --mount --uts --ipc --net --pid"

        if [ -z "$1" ]; then
            # No command given.
            # Use su to clear all host environment variables except for TERM,
            # initialize the environment variables HOME, SHELL, USER, LOGNAME, PATH,
            # and start a login shell.
            #sudo $NSENTER "$OPTS" su - root
            $kSudo $NSENTER --target $PID --mount --uts --ipc --net --pid su - root
        else
            # Use env to clear all host environment variables.
            $kSudo $NSENTER --target $PID --mount --uts --ipc --net --pid env -i $@
        fi
    fi
}


### other docker commands
_docker_ps() {
    docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}" $*
}
_docker_pgrep() {
    [ $# -ne 1 ] && return 1
    _docker_ps -a | grep "$1"
}
_docker_pname() {
    [ $# -ne 1 ] && return 1
    _docker_ps -a --filter "name=$1"
}
_docker_stopall() {
    [ $# -gt 0 ] && return 1
    local ctids=($(_docker_ps -f status=running --format "{{.ID}}"))
    local ctnames=($(_docker_ps -f status=running --format "{{.Names}}"))
    local ctlen=${#ctids[@]}
    [ $ctlen -le 0 ] && printx "[*] No running containers\n\n" && return 0

    local idx=0
    while [ $idx -lt $ctlen ]; do
        printx @green "    [$idx] stop ${ctnames[idx]}: "
        docker stop ${ctids[idx]}
        idx=$((idx+1))
    done
    echo
}
_docker_rmall() {
    [ $# -gt 0 ] && return 1
    local ctids=($(_docker_ps -f status=created -f status=exited --format "{{.ID}}"))
    local ctlen=${#ctids[@]}
    [ $ctlen -le 0 ] && printx "[*] No exited containers\n\n" && return 0

    local ctnames=($(_docker_ps -f status=created -f status=exited --format "{{.Names}}"))
    printx @yellow "[*] Exited containers: \n"
    echo "   " ${ctnames[@]}

    printx @yellow "[*] Remove all exited containers (y/n)? " && read ch 
    [ "$ch" != "y" ] && return 0

    local idx=0
    while [ $idx -lt $ctlen ]; do
        printx @green "    [$idx] remove ${ctnames[idx]}: "
        docker rm ${ctids[idx]}
        idx=$((idx+1))
    done
    echo
}
_docker_sh() {
    [ $# -lt 1 ] && echo "usage: docker-sh [opt] IMAGE" && return 1
    $kPty docker run -it $* sh
}

## set image tips
_docker_images_tips() {
    [ $# -ne 1 ] && return 1
    local opts=$(docker images | grep -v "REPOSITORY\|<none>" | awk '{print $1":"$2}')
    _tablist "$1" "$opts"
}
_docker_sh_tips() { 
    _docker_images_tips docker-sh 
}

## set ps containter tips
_docker_ps_tips() {
    [ $# -lt 1 -o $# -gt 2 ] && return 1
    local opt
    [ $# -eq 2 ] && opt="$2"
    local opts=$(_docker_ps $opt | grep -v CONTAINER | awk '{gsub(/\n/,"",$NF);print $NF}')
    _tablist "$1" "$opts"
}
_docker_ip_tips() {
    _docker_ps_tips docker-ip "-f status=running"
}
_docker_pid_tips() {
    _docker_ps_tips docker-pid "-f status=running"
}
_docker_enter_tips() {
    _docker_ps_tips docker-enter "-f status=running"
}

_docker_mingw() {
    [ "$kUname" != "MINGW" ] && return 1

    local VM=default
    local VBOXMANAGE
    local DOCKER_MACHINE=docker-machine.exe
    
    which $DOCKER_MACHINE >/dev/null 2>&1 || return 1
    
    if [ ! -z "$VBOX_MSI_INSTALL_PATH" ]; then
      VBOXMANAGE=${VBOX_MSI_INSTALL_PATH}VBoxManage.exe
    else
      VBOXMANAGE=${VBOX_INSTALL_PATH}VBoxManage.exe
    fi

    local BLUE='\033[1;34m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'

    if [ ! -f "${VBOXMANAGE}" ]; then
      echo "Either VirtualBox or Docker Machine are not installed. Please re-run the Toolbox Installer and try again."
      return 1
    fi

    "${VBOXMANAGE}" showvminfo $VM &> /dev/null
    local VM_EXISTS_CODE=$?

    set -e

    if [ $VM_EXISTS_CODE -eq 1 ]; then
      echo "Creating Machine $VM..."
      $DOCKER_MACHINE rm -f $VM &> /dev/null || :
      rm -rf ~/.docker/machine/machines/$VM
      $DOCKER_MACHINE create -d virtualbox --virtualbox-memory 2048 $VM
    else
      echo "Machine $VM already exists in VirtualBox."
    fi

    echo "Starting machine $VM..."
    $DOCKER_MACHINE start $VM

    echo "Setting environment variables for machine $VM..."
    eval "$($DOCKER_MACHINE env --shell=bash $VM)"

    clear
    cat << EOF


                        ##         .
                  ## ## ##        ==
               ## ## ## ## ##    ===
           /"""""""""""""""""\___/ ===
      ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~
           \______ o           __/
             \    \         __/
              \____\_______/

EOF
    echo -e "${BLUE}docker${NC} is configured to use the ${GREEN}$VM${NC} machine with IP ${GREEN}$($DOCKER_MACHINE ip $VM)${NC}."
    echo "For help getting started, check out the docs at https://docs.docker.com."
    echo "NOTE: When using interactive commands, prepend winpty."
    echo "Examples: 'winpty docker run -it ...', 'winpty docker exec -it ...'."
    echo
}


## -----------
## for docker-ctrl
_info_image() {
    local idx=0 sec=$1 key
    for key in `mapkey $sec`
    do
        echo "[$idx] $key=$(mapget \"$sec\" \"$key\")"
        idx=$((idx+1))
    done
    echo
    return 0
}

_gen_config() {
    local fname="$1"
    [ -f "$fname" ] && printxln @yellow "[WARN] $fname exists!\n" && return 1

    cat >> "$fname" << EOF
[jenkins]
opt=-d -it -p 8080:8080 ;-v /var/zdisk/var/lib/jenkins/plugins:/var/lib/jenkins/plugins
env=
img=peterxu/jenkins:latest
cmd=/root/bin/init

[openldap]
opt=-d
env=-e LDAP_ORGANISATION="My Compagny" -e LDAP_DOMAIN="my-compagny.com" -e LDAP_ADMIN_PASSWORD="JonSn0w"
img=osixia/openldap
cmd=

[ubuntu]
opt=-it -v /var/zdisk/wspace:/root/wspace
env=
img=ubuntu:14.04
cmd=bash

EOF
}

_docker_ctrl() {
    local todo="" image=""
    local fname="$HOME/.docker/dkctrl.ini"

    local opts="hcli:"
    local args=`getopt $opts $*`
    [ $? != 0 ] && __help_docker_ctrl && return 1

    set -- $args
    for i; do
        case "$i" in
            -h) __help_docker_ctrl; return 0;;
            -c) _gen_config "$fname"; return 0;;
            -l) todo="list"; shift;;
            -i) todo="info"; image="$2"; shift; shift;;
            --) shift; break;;
        esac
    done

    [ "$todo" = "" -a $# -lt 1 ] && __help_docker_ctrl && return 1

    ini_parse "$fname"
    if [ $? -ne 0 ]; then
        printx @red "[ERROR] " && printxln "Invalid $fname\n"
        return 1
    fi

    if [ "$todo" = "list" ]; then
        local secs=`ini_secs "$fname"` || return 1
        printxln ${secs//' '/'\n'} "\n"
    elif [ "$todo" = "info" ]; then
        _info_image "$image"
    else
        [ $# -le 0 ] && __help_docker_ctrl && return 1
        local str opt env img cmd
        for sec in $*; do
            img=$(mapget "$sec" "img")
            if [ "$img" = "" ]; then
                printx @y "[WARN] " && printxln "No such section: $sec"
                continue
            fi
            opt=$(mapget "$sec" "opt")
            env=$(mapget "$sec" "env")
            cmd=$(mapget "$sec" "cmd")
            str="docker run $opt $env $img $cmd"
            printx @green "[INFO] " && printxln "$str" 
            eval $str
        done
        echo
    fi
    return 0
}


### -----------
### init docker
__init_docker() {
    alias docker-psa="_docker_ps -a"
    alias docker-pgrep="_docker_pgrep"
    alias docker-ls="docker images"
    alias docker-stopa="_docker_stopall"
    alias docker-rma="_docker_rmall"
    alias docker-mingw="_docker_mingw"
    
    alias docker-sh="_docker_sh"
    complete -F _docker_sh_tips docker-sh

    alias docker-enter="_docker_enter"
    complete -F _docker_enter_tips docker-enter

    alias docker-pid="docker inspect --format '{{.State.Pid}}'"
    complete -F _docker_pid_tips docker-pid

    alias docker-ip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'"
    complete -F _docker_ip_tips docker-ip

    alias docker-ctrl="_docker_ctrl"
}

__help_docker_ctrl() {
    local prog="docker-ctrl"
    cat > /dev/stdout << EOF
usage:
    $prog [-h | -l | -i image | image1 [image2 ..]]
        -h:         help
        -c:         generate <\$HOME/.docker/dkctrl.ini> if not exists
        -l:         list available objects
        -i image:   list image's config

EOF
    return 0
}

__help_docker() {
    echo "usage: "
    local prefix="    [.]"
    echo
    printf "%-20s %s\n" "$prefix docker-psa"    "Like docker ps -a"
    printf "%-20s %s\n" "$prefix docker-pgrep"  "Like docker ps -a | grep .."
    printf "%-20s %s\n" "$prefix docker-ls"     "Like docker images"
    printf "%-20s %s\n" "$prefix docker-stopa"  "Stop all running containers"
    printf "%-20s %s\n" "$prefix docker-rma"    "Remove all containers"
    printf "%-20s %s\n" "$prefix docker-mingw"  "Init mingw env"
    printf "%-20s %s\n" "$prefix docker-sh"     "Run /bin/sh in one image"
    printf "%-20s %s\n" "$prefix docker-enter"  "Enter one running container"
    printf "%-20s %s\n" "$prefix docker-pid"    "Acquire the pid of one image or container"
    printf "%-20s %s\n" "$prefix docker-ip"     "Acquire the ip of one image or container"
    printf "%-20s %s\n" "$prefix docker-ctrl"   "Control to run docker image by config"
    echo
}

