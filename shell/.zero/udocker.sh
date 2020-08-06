# Some useful commands to use docker.
# Author: yeasy@github
# Created:2014-09-25
#
# Update: peter@uskee.org
# Modified: 2015/09/01


#the implementation refs from https://github.com/jpetazzo/nsenter/blob/master/docker-enter
_docker_enter() {
    #Change for centos bash running
    if [ -e $(dirname '$0')/nsenter ]; then
        # with boot2docker, nsenter is not in the PATH but it is in the same folder
        NSENTER=$(dirname "$0")/nsenter
    else
        # if nsenter has already been installed with path notified, here will be clarified
        NSENTER=$(which nsenter)
    fi

    if [ -z "$1" ]; then
        echo "Usage: `basename "$0"` CONTAINER [COMMAND [ARG]...]"
        echo ""
        echo "Enters the Docker CONTAINER and executes the specified COMMAND."
        echo "If COMMAND is not specified, runs an interactive shell in CONTAINER."
    elif [ ! -z "$NSENTER" ]; then
        PID=$(docker inspect --format "{{.State.Pid}}" "$1")
        if [ -z "$PID" ]; then
            echo "WARN Cannot find the given container"
            return
        fi
        shift

        OPTS="--target $PID --mount --uts --ipc --net --pid"

        local kSudo="sudo"
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
    else
        $kSudo docker start $@
        $kSudo docker attach $@
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
    local ctnames=($(_docker_ps -f status=running --format "{{.Names}}"))
    local ctlen=${#ctnames[@]}
    [ $ctlen -le 0 ] && _printx "[*] No running containers\n\n" && return 0

    _printx @yellow "[*] Running containers: \n"
    echo "   " ${ctnames[@]}

    local ch
    _printx @yellow "[*] Stop all (y/n)? " && read ch 
    [ "$ch" != "y" ] && return 0

    local idx=0
    while [ $idx -lt $ctlen ]; do
        _printx @green "    [$idx] stop ${ctnames[idx]}: "
        docker stop ${ctnames[idx]}
        idx=$((idx+1))
    done
    echo
}
_docker_rm() {
    [ $# -le 0 ] && return 1
    local opts
    for opt in $*; do
        opts="$opts -f status=$opt"
    done

    local ctnames=($(_docker_ps $opts --format "{{.Names}}"|grep -v "data$\|data_"))
    local ctlen=${#ctnames[@]}
    [ $ctlen -le 0 ] && _printx "[*] No exited containers\n\n" && return 0

    _printx @yellow "[*] Exited containers: \n"
    echo "   " ${ctnames[@]}

    local ch
    _printx @yellow "[*] Remove all exited containers (y/n)? " && read ch 
    [ "$ch" != "y" ] && return 0

    local idx=0
    while [ $idx -lt $ctlen ]; do
        _printx @green "    [$idx] remove ${ctnames[idx]}: "
        docker rm ${ctnames[idx]}
        idx=$((idx+1))
    done
    echo
}
_docker_rma() {
    _docker_rm "exited"
}
_docker_rmf() {
    _docker_rm "exited" "created"
}
_docker_sh() {
    [ $# -lt 1 ] && echo "usage: docker-sh [opt] IMAGE" && return 1
    local kPty=""
    [ "$_UNAME" = "MINGW" ] && kPty="winpty"
    $kPty docker run -it $* sh
}
_docker_bash() {
    [ $# -lt 1 ] && echo "usage: docker-bash [opt] IMAGE" && return 1
    local kPty=""
    [ "$_UNAME" = "MINGW" ] && kPty="winpty"
    $kPty docker run -it $* bash
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
_docker_bash_tips() { 
    _docker_images_tips docker-bash 
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
    [ "$_UNAME" != "MINGW" ] && return 1

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
    [ -f "$fname" ] && _printx @yellow "[WARN] $fname exists!\n\n" && return 1

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
 

_docker_todo() { # usage: _docker_todo action section
    [ $# -ne 2 ] && return 1
    local action="$1" sec="$2" img opt env cmd str
    if [ "$action" = "run" ]; then
        _docker_ps -a --format "{{.Names}}" | grep "^$sec$" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            docker start "$sec"
            _printx @y "[WARN] <$sec> has been existed!\n\n"
            return;
        fi

        img=$(mapget "$sec" "img")
        if [ "$img" = "" ]; then
            _printx @y "[WARN] " && _printx "No such section: $sec\n"
            return 1
        fi
        opt=$(mapget "$sec" "opt")
        env=$(mapget "$sec" "env")
        cmd=$(mapget "$sec" "cmd")
        str="docker run $opt --name=\"$sec\" $env $img $cmd"
    else
        case "$action" in
            rm) str="docker stop $sec >/dev/null 2>&1; docker rm $sec >/dev/null 2>&1";;
            *) str="docker $action $sec";;
        esac
    fi
    _printx @green "[INFO] " && _printx "cmd => $str\n" 
    eval $str
}
_docker_ctrl() {
    local todo="" image="" action=""
    local fname="$HOME/.docker/dkctrl.ini"

    local opts="hcli:a:"
    local args=`getopt $opts $*`
    [ $? != 0 ] && __help_docker_ctrl && return 1

    set -- $args
    for i; do
        case "$i" in
            -h) __help_docker_ctrl; return 0;;
            -c) _gen_config "$fname"; return 0;;
            -l) todo="list"; shift;;
            -i) todo="info"; image="$2"; shift; shift;;
            -a) todo="todo"; action="$2"; shift; shift;;
            --) shift; break;;
        esac
    done
    [ "$todo" = "" ] && __help_docker_ctrl && return 1

    _ini_parse "$fname"
    if [ $? -ne 0 ]; then
        _printx @red "[ERROR] " && _printx "Invalid $fname\n\n"
        return 1
    fi

    if [ "$todo" = "list" ]; then
        local secs=`_ini_secs "$fname"` || return 1
        local sec imgs groups desc idx1=0 idx2=0
        for sec in $secs; do
            sec=$(_trim $sec)
            if [ ${sec:0:1} = "@" ]; then
                desc=$(_mapget "$sec" "items")
                groups="$groups  [$idx2] ${sec}:    ${desc}\n"
                idx2=$((idx2+1))
            else
                imgs="$imgs  [$idx1] ${sec}\n"
                idx1=$((idx1+1))
            fi
        done
        _printx @g "[*] containers:\n" && _printx "$imgs\n"
        _printx @g "[*] groups:\n" && _printx "$groups\n"
    elif [ "$todo" = "info" ]; then
        _info_image "$image"
    elif [ "$todo" = "todo" ]; then
        [ $# -le 0 -o "$action" = "" ] && __help_docker_ctrl && return 1

        local sec
        for sec in $*; do
            if [ ${sec:0:1} = "@" ]; then
                local items=$(_mapget "$sec" "items")
                for sec in $items; do
                    if [[ "$sec" != *[!0-9]* ]]; then
                        sleep $sec 2>/dev/null
                    else
                        _docker_todo  "$action" "$sec" || return 1
                    fi
                done
                echo
            else
                _docker_todo  "$action" "$sec" || return 1
            fi
        done
        echo
    fi
}

_docker_buildx() {
    local opt="" tag=""
    if [ $# -eq 1 ]; then
        opt="-n" && tag="$1"
    elif [ $# -eq 2 ]; then
        opt="$1" && tag="$2"
    fi
    [ "$opt" != "-y" -a "$opt" != "-n" ] && echo "usage: docker-buildx [-y] tag" && return 0

    local name=$(basename $(pwd))
    [ ${#name} -lt 3 ] && echo "[WARN] ${name} is too short!" && return 1
    echo "[INFO] To build lark.io/$name:$tag ..."
    local ch="y"
    [ "$opt" != "-y" ] && _printx @green "[INFO] continue (y/n)? " && read ch
    echo
    [ "$ch" != "y" ] && return 0
    docker build -t lark.io/$name:$tag .
}

_docker_pushx() {
    local opt="" tag=""
    if [ $# -eq 1 ]; then
        opt="-n" && tag="$1"
    elif [ $# -eq 2 ]; then
        opt="$1" && tag="$2"
    fi
    [ "$opt" != "-y" -a "$opt" != "-n" ] && echo "usage: docker-pushx [-y] tag" && return 0

    local name=$(basename $(pwd))
    [ ${#name} -lt 3 ] && echo "[WARN] ${name} is too short!" && return 1
    echo "[INFO] To push lark.io/$name:$tag ..."
    local ch="y"
    [ "$opt" != "-y" ] && _printx @green "[INFO] continue (y/n)? " && read ch
    echo

    [ "$ch" != "y" ] && return 0
    docker push lark.io/$name:$tag
}


### -----------
### init docker
__init_docker() {
    #return 

    # for image
    alias docker-ls="docker images"
    alias docker-untagged="docker images --filter dangling=true"
    #alias docker-untagged-id="docker images -q -f dangling=true"
    #alias docker-sh="_docker_sh"
    #completex _docker_sh_tips docker-sh
    alias docker-bash="_docker_bash"
    completex _docker_bash_tips docker-bash

    # for container
    alias docker-psa="_docker_ps -a"
    #alias docker-pgrep="_docker_pgrep"
    #alias docker-stopa="_docker_stopall"
    #alias docker-rma="_docker_rma"
    #alias docker-rmf="_docker_rmf"
    alias docker-enter="_docker_enter"
    completex _docker_enter_tips docker-enter
    #alias docker-pid="docker inspect --format '{{.State.Pid}}'"
    #completex _docker_pid_tips docker-pid
    alias docker-ip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'"
    completex _docker_ip_tips docker-ip

    # for docker build/push
    alias docker-buildx="_docker_buildx"
    alias docker-pushx="_docker_pushx"

    alias docker-mingw="_docker_mingw"
    #alias docker-ctrl="_docker_ctrl"
    #mkdir -p "$HOME/.docker" >/dev/null 2>&1
}

__help_docker_ctrl() {
    local prog="docker-ctrl"
    cat > /dev/stdout << EOF
usage:
    $prog [-h | -l | -i item | -a [run|start|stop|restart|rm] | item1 [item2 ..]]
        -h:         help
        -c:         generate <\$HOME/.docker/dkctrl.ini> if not exists
        -l:         list available objects
        -a:         todo for item
        -i image:   list item config

EOF
    return 0
}

__help_docker() {
    echo "usage: "
    local fmt="%-30s %s" prefix="    [.]"
    echo
    printf "$fmt\n" "$prefix docker-ls"             "Like docker images"
    printf "$fmt\n" "$prefix docker-untagged"       "List untagged docker images"
    printf "$fmt\n" "$prefix docker-ctrl"           "Control to run docker image by config"
    printf "$fmt\n" "$prefix docker-buildx"         "Auto build from current directory"
    printf "$fmt\n" "$prefix docker-pushx"          "Auto push according to docker-buildx"

    printf "$fmt\n" "$prefix docker-psa"    "Like docker ps -a"
    printf "$fmt\n" "$prefix docker-pgrep"  "Like docker ps -a | grep .."
    printf "$fmt\n" "$prefix docker-stopa"  "Stop all running containers"
    printf "$fmt\n" "$prefix docker-rma"    "Remove all containers"
    printf "$fmt\n" "$prefix docker-enter"  "Enter one running container"
    printf "$fmt\n" "$prefix docker-pid"    "Acquire the pid of one image or container"
    printf "$fmt\n" "$prefix docker-ip"     "Acquire the ip of one image or container"

    printf "$fmt\n" "$prefix docker-mingw"  "Init mingw env"
    echo
    printf "$fmt\n" "    For general users, should set 'sudo usermod -aG docker username'"
    printf "$fmt\n" "    For private registry, set as below:"
    printf "$fmt\n" "       update /lib/systemd/system/docker.service:"
    printf "$fmt\n" "       EnvironmentFile=-/etc/default/docker"
    printf "$fmt\n" "       ExecStart=/usr/bin/docker daemon $DOCKER_OPTS -H fd://"
    echo
}

