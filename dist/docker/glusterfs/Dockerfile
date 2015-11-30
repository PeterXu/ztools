FROM xdocker.host:5000/ubuntu:latest
MAINTAINER Peter <peter@uskee.org>
LABEL "org.uskee.vendor"="Peter"


## update apt-get repo
ADD sources.list /etc/apt/
RUN apt-get update
RUN apt-get install -y apt-utils fuse portmap net-tools uuid sqlite3 python attr
RUN apt-get install -y libssl1.0.0 libuuid1 libsqlite3-0 libxml2 libreadline6 libncurses5
#RUN apt-get install -y python-ctypeslib python-simplejson
RUN apt-get install -y libaio1 libacl1 libattr1 libcmocka0 liburcu1 libibverbs1 librdmacm1
RUN apt-get -f install
RUN apt-get autoremove
RUN apt-get clean


## work script
WORKDIR /root
RUN mkdir -p /root/bin
ADD glusterdctl /root/bin

ADD glusterfs-bin.tar.gz /root
RUN mv /root/var/lib/glusterfs /var/lib/
RUN rm -rf /root/var
RUN touch /var/lib/glusterfs/var/lib/glusterd/glusterd.info
RUN echo "global-option-version=0" > /var/lib/glusterfs/var/lib/glusterd/options
#VOLUME ["/var/lib/gdata"]


## start program and args
ENV PATH "$PATH:/root/bin:/var/lib/glusterfs/bin:/var/lib/glusterfs/sbin"
#ENTRYPOINT [""]
CMD ["/var/lib/glusterfs/sbin/glusterd", "-N", "-p", "/var/run/glusterd.pid", "-f", "/var/lib/glusterfs/etc/glusterfs/glusterd.vol"]

