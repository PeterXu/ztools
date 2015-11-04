# Some useful commands to use docker.
# Author: yeasy@github
# Created:2014-09-25
#
# Update: peter@uskee.org
# Modified: 2015/09/01

kUname=$(uname)
[[ "$kUname" =~ "MINGW" || "$kUname" =~ "mingw" ]] && kUname="MINGW"
[ "$kUname" = "Linux" ] && kSudo="sudo"
[ "$kUname" = "MINGW" ] && kPty="winpty"


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
        PID=$($kSudo docker inspect --format "{{.State.Pid}}" "$1")
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
        $kSudo docker rm ${ctids[idx]}
        idx=$((idx+1))
    done
    echo
}
_docker_bash() {
    [ $# -lt 1 ] && echo "usage: dk-bash [opt] IMAGE" && return 1
    local cmd="/bin/bash"
    [ "$kUname" = "MINGW" ] && cmd="bash"
    $kPty docker run -it $* $cmd
}

## set image tips
_dk_images_tips() {
    [ $# -ne 1 ] && return 1
    local opts=$(docker images | grep -v "REPOSITORY\|<none>" | awk '{print $1":"$2}')
    _tablist "$1" "$opts"
}
_dk_run() { 
    _dk_images_tips dk-run 
}
_dk_bash() { 
    _dk_images_tips dk-bash 
}
_dk_rmi() { 
    _dk_images_tips dk-rmi 
}

## set ps containter tips
_dk_ps_tips() {
    [ $# -lt 1 -o $# -gt 2 ] && return 1
    local opt
    [ $# -eq 2 ] && opt="$2"
    local opts=$(_docker_ps $opt | grep -v CONTAINER | awk '{gsub(/\n/,"",$NF);print $NF}')
    _tablist "$1" "$opts"
}
_dk_rm() {
    _dk_ps_tips dk-rm "-f status=created -f status=exited"
}
_dk_attach() {
    _dk_ps_tips dk-attach "-f status=running"
}
_dk_start() {
    _dk_ps_tips dk-start "-f status=created -f status=exited"
}
_dk_stop() {
    _dk_ps_tips dk-stop "-f status=running"
}
_dk_restart() {
    _dk_ps_tips dk-restart "-f status=running"
}
_dk_pause() {
    _dk_ps_tips dk-pause "-f status=running"
}
_dk_unpause() {
    _dk_ps_tips dk-unpause "-f status=paused"
}
_dk_ip() {
    _dk_ps_tips dk-ip "-f status=running"
}
_dk_pid() {
    _dk_ps_tips dk-pid "-f status=running"
}
_dk_enter() {
    _dk_ps_tips dk-enter "-f status=running"
}



### init docker
__init_docker() {
    local cmdlist=$(docker -h | grep "^    [a-z]" | awk -F" " '{print $1}')
    for cmd in $cmdlist; do
        alias dk-$cmd="$kSudo docker $cmd"
    done

    alias dk="docker"
    alias dk-rma="_docker_rmall"
    alias dk-pgrep="_docker_pgrep"
    alias dk-bash="_docker_bash"
    alias dk-enter="_docker_enter"
    alias dk-ps="_docker_ps"
    alias dk-psa="_docker_ps -a"

    alias dk-ls="docker images"
    alias dk-pid="$kSudo docker inspect --format '{{.State.Pid}}'"
    alias dk-ip="$kSudo docker inspect --format '{{ .NetworkSettings.IPAddress }}'"

    complete -F _dk_rmi dk-rmi
    complete -F _dk_run dk-run
    complete -F _dk_bash dk-bash

    complete -F _dk_rm dk-rm
    complete -F _dk_attach dk-attach
    complete -F _dk_start dk-start
    complete -F _dk_stop dk-stop
    complete -F _dk_restart dk-restart
    complete -F _dk_pause dk-pause
    complete -F _dk_unpause dk-unpause

    complete -F _dk_ip dk-ip
    complete -F _dk_pid dk-pid
    complete -F _dk_enter dk-enter
}

__help_docker() {
    echo "usage: "
    local prefix="    [.]"
    docker -h | grep "^    [a-z]" | sed "s/^    \([a-z]\)/$prefix dk-\1/"
    echo
    printf "%-20s %s\n" "$prefix dk-psa"    "Like dk-ps -a"
    printf "%-20s %s\n" "$prefix dk-pgrep"  "Like dk-ps -a | grep .."
    printf "%-20s %s\n" "$prefix dk-rma"    "Remove all containers"
    printf "%-20s %s\n" "$prefix dk-pid"    "Acquire the pid of one image or container"
    printf "%-20s %s\n" "$prefix dk-ip"     "Acquire the ip of one image or container"
    printf "%-20s %s\n" "$prefix dk-bash"   "Run /bin/bash in one image"
    echo
}

