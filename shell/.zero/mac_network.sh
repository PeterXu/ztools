#!/bin/bash 


__help_mac_netctl() {
    local modes=("100% Loss" 3G DSL Edge LTE "Very Bad Network" "Wi-Fi" "Wi-Fi 802.11ac")
    local prog="mac_netctl"
    echo "usage: $prog start <mode>|stop, supported modes:"
    idx=0
    for m in "${modes[@]}"; do
        echo "  $idx: \"$m\""
        idx=$((idx+1))
    done
}

function __mac_netctl_stop() {
    echo "Resetting network conditioning..."
    (
    set -e
    sudo dnctl -q flush
    sudo pfctl -f /etc/pf.conf 
    echo "done"
    )
    return 0
}

function __mac_netctl_start() {
    local mode="$1"
    local down_bandwidth, down_packets_dropped, down_delay
    local up_bandwidth, up_packets_dropped, up_delay
    if [ "$mode" = "100% Loss" ]; then
        down_bandwidth="0Kbit/s"
        down_packets_dropped="1.0"
        down_delay="0"
        up_bandwidth="0Kbit/s"
        up_packets_dropped="1.0"
        up_delay="0"
    elif [ "$mode" = "3G" ]; then
        down_bandwidth="780Kbit/s"
        down_packets_dropped="0.0"
        down_delay="100"
        up_bandwidth="330Kbit/s"
        up_packets_dropped="0.0"
        up_delay="100"
    elif [ "$mode" = "DSL" ]; then
        down_bandwidth="2Mbit/s"
        down_packets_dropped="0.0"
        down_delay="5"
        up_bandwidth="256Kbit/s"
        up_packets_dropped="0.0"
        up_delay="5"
    elif [ "$mode" = "Edge" ]; then
        down_bandwidth="240Kbit/s"
        down_packets_dropped="0.0"
        down_delay="400"
        up_bandwidth="200Kbit/s"
        up_packets_dropped="0.0"
        up_delay="440"
    elif [ "$mode" == "LTE" ]; then
        down_bandwidth="50Mbit/s"
        down_packets_dropped="0.0"
        down_delay="50"
        up_bandwidth="10Mbit/s"
        up_packets_dropped="0.0"
        up_delay="65"
    elif [ "$mode" = "Very Bad Network" ]; then
        down_bandwidth="1Mbit/s"
        down_packets_dropped="0.1"
        down_delay="500"
        up_bandwidth="1Mbit/s"
        up_packets_dropped="0.1"
        up_delay="500"
    elif [ "$mode" = "Wi-Fi" ]; then
        down_bandwidth="40Mbit/s"
        down_packets_dropped="0.0"
        down_delay="1"
        up_bandwidth="33Mbit/s"
        up_packets_dropped="0.0"
        up_delay="1"
    elif [ "$mode" = "Wi-Fi 802.11ac" ]; then
        down_bandwidth="250Mbit/s"
        down_packets_dropped="0.0"
        down_delay="1"
        up_bandwidth="100Mbit/s"
        up_packets_dropped="0.0"
        up_delay="1"
    else
        echo "Mode '$mode' is not a valid mode."
        __help_mac_netctl
        return 1
    fi

    echo "Starting network conditioning..."

    (
    set -e
    (cat /etc/pf.conf && echo "dummynet-anchor \"conditioning\"" && echo "anchor \"conditioning\"") | sudo pfctl -f -
    sudo dnctl pipe 1 config bw "$down_bandwidth" plr "$down_packets_dropped" delay "$down_delay"
    sudo dnctl pipe 2 config bw "$up_bandwidth" plr "$up_packets_dropped" delay "$up_delay"
    echo "dummynet out quick proto tcp from any to any pipe 1" | sudo pfctl -a conditioning -f -
    echo "dummynet in quick proto tcp from any to any pipe 2" | sudo pfctl -a conditioning -f -

    #set +e
    sudo pfctl -e
    echo "done"
    )

    return 0
}

function mac_netctl() {
    local start_stop="$1"
    local mode="$2"
    if [ "$start_stop" = "stop" ]; then
        if [ "N$mode" != "N" ]; then
            __help_mac_netctl
        else
            __mac_netctl_stop
        fi
    elif [ "$start_stop" = "start" ]; then
        __mac_netctl_start "$mode"
    else
        __help_mac_netctl
    fi
}

