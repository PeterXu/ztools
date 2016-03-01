#!/bin/sh

options=""
update="yes"

set_kernel() {
    # ipcs -l | ipcs -u
    options="#kernel.sysrq=0"
    options="$options #kernel.core_uses_pid=1"
    # default max size of queue (bytes)
    options="$options #kernel.msgmnb=65536"
    # max queues system wide 
    options="$options #kernel.msgmax=65536"

    # max seg size (kbytes), 64T
    #options="$options #kernel.shmmax=68719476736"
    # max total shared memory (kbytes), 4T
    #options="$options #kernel.shmall=4294967296"
    # max number of segments
    #options="$options #kernel.shnmni=4096"

    ## others
    # /proc/sys/kernel/ctrl-alt-del, default 0 like poweroff, 1 like shutdown.
    # /proc/sys/kernel/panic, 0 means to forbid auto-reboot
    # /proc/sys/kernel/threads-max, max threads in kernel
}

set_net_core() {
    # default 212992
    options="#net.core.wmem_default=8388608"
    # default 212992
    options="$options #net.core.rmem_default=8388608"
    # default 212992
    options="$options #net.core.rmem_max=16777216"
    # default 212992
    options="$options #net.core.wmem_max=16777216"
    # default 1000
    options="$options #net.core.netdev_max_backlog=262144"
    # default 128
    options="$options #net.core.somaxconn=262144"
}

set_net_ipv4() {
    options="#net.ipv4.ip_forward=0"
    # reverse-pathfiltering, discrad if IP is not fit.
    options="$options #net.ipv4.conf.default.rp_filter=0"
    options="$options #net.ipv4.conf.all.rp_filter=0"
    # forbid ICMP source route
    options="$options #net.ipv4.conf.default.accept_source_route=0"
    # port range, default 32768-61000
    options="$options #net.ipv4.ip_local_port_range=10240 65000"
}

set_net_ipv4_tcp() {
    options="#net.ipv4.tcp_sack=1"
    options="$options #net.ipv4.tcp_window_scaling=1"
    options="$options #net.ipv4.tcp_rmem=4096 87380 16777216"
    options="$options #net.ipv4.tcp_wmem=4096 65536 16777216"
    options="$options #net.ipv4.tcp_max_orphans=262144"
    options="$options #net.ipv4.tcp_timestamps=0"
    options="$options #net.ipv4.tcp_mem=1543458 2057947 3086916"

    # the time of FIN_WAIT_2 if socket is closed by local, default 60
    options="$options #net.ipv4.tcp_fin_timeout=10"
    # time of keepalive: seconds, default 7200
    options="$options #net.ipv4.tcp_keepalive_time=60"

    ## for SYN
    # when SYN overflow, use cookies
    options="$options #net.ipv4.tcp_syncookies=1" 
    # the queue of waiting SYN, default 1024, 
    options="$options #net.ipv4.tcp_max_syn_backlog=262144"
    options="$options #net.ipv4.tcp_syn_retries=1"
    options="$options #net.ipv4.tcp_synack_retries=1"

    ## for TIME_WAIT
    # allow TIME_WAIT connection for new TCP
    options="$options #net.ipv4.tcp_tw_reuse=1"
    # enable fast recycle of TIME_WAIT socket
    options="$options #net.ipv4.tcp_tw_recycle=1"
    # the max number of TIME_WAIT, cleared if larger than this.
    options="$options #net.ipv4.tcp_max_tw_buckets=262144"
}

do_sysctl() {
    local opt key val old new idx=-1
    OFS="$IFS"
    IFS="#"
    for opt in $options ; do 
        [ "$opt" = "" ] && continue
        key=${opt%%=*}
        val=${opt##*=}
        if [ ${#key} -le 5 ]; then
            echo "[WARN] invalid key: $key"
            continue
        fi

        old=`sysctl $key 2>/dev/null` && old=`echo $old`
        if [ "$old" = "" ]; then
            echo "[WARN] no <$key> in sysctl"
            continue
        fi

        if [ "$update" = "yes" ]; then
            sysctl -w $key="$val" 2>/dev/null 1>&2 || exit 1
            new=`sysctl $key 2>/dev/null` && new=`echo $new`
            if [ "$old" = "$new" ]; then
                echo "[WARN] fail to set <$key> with <$val>, current:<$new>"
                continue
            fi
            idx=$((idx+1))
            printf "[%2d] %-50s  =>  %s\n" "$idx" "$old" "$new"
        else
            idx=$((idx+1))
            printf "[%2d] %-50s => %s\n" "$idx" "$old" "$val"
        fi
    done 
    IFS="$OFS"
}

main() {
    set_kernel && do_sysctl
    echo
    set_net_core && do_sysctl
    echo
    set_net_ipv4 && do_sysctl
    echo
    set_net_ipv4_tcp && do_sysctl
    echo
}


update="no"
main
exit 0
