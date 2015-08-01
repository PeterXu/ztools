#!/bin/sh

options=""
options="$options #net.ipv4.tcp_tw_recycle=1"
options="$options #net.ipv4.ip_forward=0"
options="$options #net.ipv4.conf.default.rp_filter=1"
options="$options #net.ipv4.conf.default.accept_source_route=0"
options="$options #kernel.sysrq=0"
options="$options #kernel.core_uses_pid=1"
options="$options #net.ipv4.tcp_syncookies=1"
options="$options #kernel.msgmnb=65536"
options="$options #kernel.msgmax=65536"
options="$options #kernel.shmmax=68719476736"
options="$options #kernel.shmall=4294967296"
options="$options #net.ipv4.tcp_max_tw_buckets=6000"
options="$options #net.ipv4.tcp_sack=1"
options="$options #net.ipv4.tcp_window_scaling=1"
options="$options #net.ipv4.tcp_rmem=4096 87380 4194304"
options="$options #net.ipv4.tcp_wmem=4096 16384 4194304"
options="$options #net.core.wmem_default=8388608"
options="$options #net.core.rmem_default=8388608"
options="$options #net.core.rmem_max=16777216"
options="$options #net.core.wmem_max=16777216"
options="$options #net.core.netdev_max_backlog=262144"
options="$options #net.core.somaxconn=262144"
options="$options #net.ipv4.tcp_max_orphans=3276800"
options="$options #net.ipv4.tcp_max_syn_backlog=262144"
options="$options #net.ipv4.tcp_timestamps=0"
options="$options #net.ipv4.tcp_synack_retries=1"
options="$options #net.ipv4.tcp_syn_retries=1"
options="$options #net.ipv4.tcp_tw_recycle=1"
options="$options #net.ipv4.tcp_tw_reuse=1"
options="$options #net.ipv4.tcp_mem=94500000 915000000 927000000"
options="$options #net.ipv4.tcp_fin_timeout=1"
options="$options #net.ipv4.tcp_keepalive_time=30"
options="$options #net.ipv4.ip_local_port_range=1024 65000"

idx=-1
OFS="$IFS"
IFS="#"
for opt in $options ; do 
    key=${opt%%=*}
    val=${opt##*=}
    [ ${#key} -le 5 ] && continue
    idx=$((idx+1))

    old=`sysctl $key 2>/dev/null` && old=`echo $old`
    [ "$old" = "" ] && continue

    sysctl -w $key="$val" 2>/dev/null 1>&2

    new=`sysctl $key 2>/dev/null` && new=`echo $new`
    [ "$new" = "" ] && continue

    #echo ${#old}
    printf "[%2d] %-50s  =>  %s\n" "$idx" "$old" "$new"
done 
IFS="$OFS"


