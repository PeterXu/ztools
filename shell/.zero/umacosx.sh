#!/bin/bash 


__help_mac_netctl() {
    local profiles=("100% Loss" 3G "Very Bad Network" "Normal Network" "Wi-Fi")
    local prog="mac-netctl"
    echo "usage: $prog start <profile_name>|stop, supported profiles:"
    idx=0
    for item in "${profiles[@]}"; do
        echo "  $idx: \"$item\""
        idx=$((idx+1))
    done
}

function _mac_netctl_stop() {
    echo "Resetting network conditioning..."
    (
    set -e
    sudo dnctl -q flush
    sudo pfctl -f /etc/pf.conf 
    echo "done"
    )
    return 0
}

function _mac_netctl_start() {
    local profile="$1"
    local down_bandwidth, down_lossrate, down_delay
    local up_bandwidth, up_lossrate, up_delay
    if [ "$profile" = "100% Loss" ]; then
        down_bandwidth="0Kbit/s"
        down_lossrate="1.0"
        down_delay="0"
        up_bandwidth="0Kbit/s"
        up_lossrate="1.0"
        up_delay="0"
    elif [ "$profile" = "3G" ]; then
        down_bandwidth="780Kbit/s"
        down_lossrate="0.0"
        down_delay="100"
        up_bandwidth="330Kbit/s"
        up_lossrate="0.0"
        up_delay="100"
    elif [ "$profile" = "Very Bad Network" ]; then
        down_bandwidth="1Mbit/s"
        down_lossrate="0.1"
        down_delay="500"
        up_bandwidth="1Mbit/s"
        up_lossrate="0.1"
        up_delay="500"
    elif [ "$profile" = "Normal Network" ]; then
        down_bandwidth="10Mbit/s"
        down_lossrate="0.03"
        down_delay="50"
        up_bandwidth="5Mbit/s"
        up_lossrate="0.01"
        up_delay="50"
    elif [ "$profile" = "Wi-Fi" ]; then
        down_bandwidth="900Mbit/s"
        down_lossrate="0.0"
        down_delay="1"
        up_bandwidth="33Mbit/s"
        up_lossrate="0.0"
        up_delay="1"
    else
        echo "Profile '$profile' is not a valid profile."
        __help_mac_netctl
        return 1
    fi

    echo "Starting network conditioning..."

    (
    set -e
    (cat /etc/pf.conf && echo "dummynet-anchor \"conditioning\"" && echo "anchor \"conditioning\"") | sudo pfctl -f -
    sudo dnctl pipe 1 config bw "$down_bandwidth" plr "$down_lossrate" delay "$down_delay"
    sudo dnctl pipe 2 config bw "$up_bandwidth" plr "$up_lossrate" delay "$up_delay"
    echo "dummynet out quick proto tcp from any to any pipe 1" | sudo pfctl -a conditioning -f -
    echo "dummynet in quick proto tcp from any to any pipe 2" | sudo pfctl -a conditioning -f -

    #set +e
    sudo pfctl -e
    echo "done"
    )

    return 0
}

function _mac_netctl() {
    local start_stop="$1"
    local profile="$2"
    if [ "$start_stop" = "stop" ]; then
        if [ "N$profile" != "N" ]; then
            __help_mac_netctl
        else
            _mac_netctl_stop
        fi
    elif [ "$start_stop" = "start" ]; then
        _mac_netctl_start "$profile"
    else
        __help_mac_netctl
    fi
}



__help_mac_netcfg() {
    local prog="mac-netcfg"
    echo "usage: $prog in|out|both [bw ..] [plr ..] [delay ..] [proto ..]"
    echo
    echo "  There should have one of bw|plr|delay at least."
    echo "      bw: bandwidth, default 900Mbit/s, also support Kbit/s"
    echo "      plr: packet lossrate[0.0, 1.0], default 0.0(no loss), 1.0 means 100% loss"
    echo "      delay: network delay(ms), default 0."
    echo
    echo "  proto: match rules, default: 'ip from any to any'"
    echo "         type: 'ip|tcp|udp', refer to /etc/protocols"
    echo "         flow: 'from any to any', "
    echo "               'from any port <= 1024 to any', "
    echo "               'from any to any port 25', "
    echo "               'from 10.0.0.0/8 port > 1024 to 10.1.2.3 port 2000:2004'"
    echo
}

function _mac_netcfg() {
    # 0: out, 1: in, 2: both
    local direction=2             # default both
    local bandwidth="900Mbit/s"   # default max
    local lossrate="0.0"          # [0.0-1.0]
    local delay="0"               # ms
    local proto="proto ip from any to any" # default all

    if [ $# -lt 3 ]; then
        __help_mac_netcfg
        return 0
    fi
    local value="$1"; shift
    case "$value" in
        in)
            direction=1
            ;;
        out)
            direction=0
            ;;
        both)
            direction=2
            ;;
        *)
            echo "[ERROR] invalid direction, should be in|out|both."
            return 1
            ;;
    esac

    local have_proto=0
    while [ $# -ge 1 ]; do
        local value="$1"; shift
        case "$value" in
            bw)
                have_proto=0
                bandwidth="$1"; shift
                local b1=${bandwidth%Mbit/s}
                local b2=${bandwidth%Kbit/s}
                if [ "$b1" = "$bandwidth" -a "$b2" = "$bandwidth" ]; then
                    echo "[ERROR] invalid bw, should be Kbit/s or Mbit/s"
                    return 1
                fi
                ;;
            plr)
                have_proto=0
                lossrate="$1"; shift
                local ival=$(echo $lossrate | awk '{if ($1 < 0 || $1 > 1.0) print -1; else print 1;}')
                if [ $ival -lt 0 ]; then
                    echo "[ERROR] invalid plr, should be [0.0, 1.0]"
                    return 1
                fi
                ;;
            delay)
                have_proto=0
                delay="$1"; shift
                ;;
            proto)
                have_proto=1
                proto="proto $1"
                ;;
            *)
                if [ $have_proto -eq 1 ]; then
                    proto="$proto $1"
                else
                    echo "[ERROR] invalid proto, see help"
                    return 1
                fi
                ;;
        esac
    done

    #echo "$direction"
    #echo "$bandwidth"
    #echo "$lossrate"
    #echo "$delay"
    #echo "$proto"
    #return 0;

    (
    # 0. exit if any fail
    set -e

    # 1.set dummynet anchor
    (cat /etc/pf.conf && echo "dummynet-anchor \"conditioning\"" && echo "anchor \"conditioning\"") | sudo pfctl -f -

    # 2. create pipe(pipe-1: out, pipe-2: in)
    if [ $direction -eq 0 -o $direction -eq 2 ]; then
        sudo dnctl pipe 1 config bw "$bandwidth" plr "$lossrate" delay "$delay"
    fi
    if [ $direction -eq 1 -o $direction -eq 2 ]; then
        sudo dnctl pipe 2 config bw "$bandwidth" plr "$lossrate" delay "$delay"
    fi

    # load pipe by anchor
    #   quick: this is last rule and skip related subsequent rules.
    if [ $direction -eq 0 -o $direction -eq 2 ]; then
        echo "dummynet out quick $proto pipe 1" | sudo pfctl -a conditioning -f -
    fi
    if [ $direction -eq 1 -o $direction -eq 2 ]; then
        echo "dummynet in quick $proto pipe 2" | sudo pfctl -a conditioning -f -
    fi

    #set +e

    # enable rules
    sudo pfctl -e
    echo "done"
    )

    return 0
}

function _chrome_update() {
    local update0="/Library/Google/GoogleSoftwareUpdate"
    if [ -d "$update0" ]; then
        echo "remove system $update0"
        sudo rm -rf "$update0"
    fi

    local update="$HOME/$update0"
    if [ ! -d "$update" ]; then
        echo "$update not exist"
        return 0
    fi

    local action="$1"
    if [ "$action" = "on" ]; then
        local owner=$(whoami)
        sudo chown $owner:staff $update
        sudo chmod 755 $update
        return 0;
    fi

    if [ "$action" = "off" ]; then
        sudo chown root:staff $update
        sudo chmod 400 $update
        return 0;
    fi

    echo "usage: chrome-update on|off"
    return 1
}


__init_macosx() {
    alias mac-netctl="_mac_netctl"
    alias mac-netcfg="_mac_netcfg"
    alias chrome-update="_chrome_update"
}

