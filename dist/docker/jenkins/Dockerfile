FROM ubuntu:latest
MAINTAINER Peter <peter@uskee.org>


#RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list
RUN apt-get update
#RUN apt-get upgrade -y

RUN apt-get install -y software-properties-common
RUN apt-get install -y default-jre default-jdk

#RUN add-apt-repository ppa:webupd8team/java
#RUN apt-get update
#RUN apt-get install -y oracle-java7-installer oracle-java7-set-default

RUN apt-get install -y daemon psmisc passwd wget
RUN apt-get install -y openssh-server subversion git

RUN apt-get -f install
RUN apt-get clean


WORKDIR /root
RUN mkdir -p bin
ADD init bin/

ADD http://pkg.jenkins-ci.org/debian-stable/binary/jenkins_1.609.3_all.deb jenkins_all.deb
RUN dpkg -i jenkins_all.deb
RUN rm -f *.deb

EXPOSE 22 8080 8443

#ENTRYPOINT ["/bin/bash"]
#CMD ["--help"]

