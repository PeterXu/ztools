FROM ubuntu:15.10
MAINTAINER Peter <peter@uskee.org>
LABEL "org.uskee.vendor"="Peter"


## update apt-get repo
ADD sources.list /etc/apt/
RUN apt-get update
RUN apt-get install -y apt-utils
RUN apt-get install -y fuse portmap libssl1.0.0 net-tools
RUN apt-get install -y python python-ctypes python-simplejson sqlite3
#RUN apt-get install -y libglib2.0-0 systemtap libcmocka0
RUN apt-get install -y libreadline6 libncurses5 libxml2
RUN apt-get install -y libuuid1 libaio1 libacl1 liburcu2 libattr1
RUN apt-get install -y liburcu2 liblvm2app2.2 libibverbs1 librdmacm1
#RUN apt-get install -y rdmacm-utils infiniband-diags
RUN apt-get -f install
RUN apt-get clean


## work script
WORKDIR /root
RUN mkdir -p /root/bin
ADD glusterdctl /root/bin

ADD glusterfs-bin.tar.gz /root
RUN mv /root/var/lib/glusterfs /var/lib/
RUN rm -rf /root/var
RUN touch /var/lib/glusterfs/var/lib/glusterd/{glusterd.info,options}
RUN echo "global-option-version=0" >/var/lib/glusterfs/var/lib/glusterd/options

VOLUME ["/var/lib/gdata"]

## start program and args
#ENTRYPOINT [""]
CMD ["/var/lib/glusterfs/sbin/glusterd", "-N", "-p", "/var/run/glusterd.pid", "-f", "/var/lib/glusterfs/etc/glusterfs/glusterd.vol"]

