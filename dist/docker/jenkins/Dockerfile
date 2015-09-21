FROM ubuntu:latest
MAINTAINER Peter <peter@uskee.org>



## update apt-get repo
#RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list
RUN apt-get update
#RUN apt-get upgrade -y
RUN apt-get install -y software-properties-common

## install common tools
RUN apt-get install -y daemon psmisc passwd openssl wget curl
RUN apt-get install -y openssh-server subversion git

## install java
RUN apt-get install -y default-jre default-jdk
#RUN add-apt-repository ppa:webupd8team/java
#RUN apt-get update
#RUN apt-get install -y oracle-java7-installer oracle-java7-set-default

## install depends
RUN apt-get -f install
RUN apt-get clean



## init script
WORKDIR /root
RUN mkdir -p bin
ADD init bin/

## install jenkins
ADD http://pkg.jenkins-ci.org/debian-stable/binary/jenkins_1.609.3_all.deb jenkins_all.deb
RUN dpkg -i jenkins_all.deb
RUN rm -f *.deb

## expose ports
EXPOSE 22 8080 8443

## start program and args
#ENTRYPOINT ["/bin/bash"]
#CMD ["--help"]

