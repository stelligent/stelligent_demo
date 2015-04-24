FROM centos:6
MAINTAINER The CentOS Project <cloud-ops@centos.org> - ami_creator

RUN yum -y update 
RUN yum -y install epel-release
RUN yum -y install sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel gcc python-pip python-devel zlib-devel bzip2-devel openssl-devel ncurses-devel wget
RUN wget https://www.python.org/ftp/python/2.7.9/Python-2.7.9.tgz
RUN tar fxvz Python-2.7.9.tgz
RUN cd Python-2.7.9
RUN ./configure --prefix=/usr/local
RUN make
RUN make altinstall 
ADD . /var/www
WORKDIR /var/www
RUN pip2.7 install -r requirements.txt
CMD python2.7 application.py

EXPOSE 8080
