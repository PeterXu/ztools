# Some useful commands to use docker.
# Author: yeasy@github
# Created:2014-09-25
#
# Update: peter@uskee.org
# Modified: 2015/09/01

[ ! `uname` = "Darwin" ] && kSudo="sudo"

alias dk-pid="$kSudo docker inspect --format '{{.State.Pid}}'"
alias dk-ip="$kSudo docker inspect --format '{{ .NetworkSettings.IPAddress }}'"

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
alias dk-enter="_docker_enter"


# Other alias
alias dk-run="$kSudo docker run"
alias dk-search="$kSudo docker search"
alias dk-ps="$kSudo docker ps"
alias dk-psa="$kSudo docker ps -a"

_docker_pgrep() {
    [ $# -ne 1 ] && return 1
    $kSudo docker ps -a | grep "$1"
}
alias dk-pgrep="_docker_pgrep"

_docker_rmall() {
    [ $# -gt 0 ] && return 1
    printx @red "[*] Remove all containers (y/n)? " && read ch 
    [ "$ch" != "y" ] && return

    containers=$($kSudo docker ps -a | grep -v CONTAINER | awk '{print $1}')
    for ct in $containers; do
        printx @green "[-] remove: "
        $kSudo docker rm $ct
    done
    echo
}
alias dk-rma="_docker_rmall"

_help_docker() {
    echo "usage: "
    echo "  dk-run/search   => docker run/search"
    echo "  dk-ps/psa       => docker ps/ps -a"
    echo "  dk-pgrep        => docker ps -a | grep"
    echo "  dk-rma          => docker rm <all containers>"
    echo "  dk-pid          => get pid of container or image"
    echo "  dk-ip           => get ip of container or image"
    echo
}
