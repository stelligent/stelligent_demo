FROM centos:6
MAINTAINER The CentOS Project <cloud-ops@centos.org> - ami_creator
RUN yum -y update 
RUN yum -y install epel-release
RUN yum -y install sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel gcc zlib-devel bzip2-devel openssl-devel ncurses-devel wget tar curl openssh-server
ADD . /var/www
WORKDIR /var/www
RUN wget -nv https://www.python.org/ftp/python/2.7.9/Python-2.7.9.tgz
RUN tar fxz Python-2.7.9.tgz
RUN cd Python-2.7.9 && ./configure --prefix=/usr/local && make && make altinstall 
RUN wget -nv https://bootstrap.pypa.io/get-pip.py
RUN python2.7 get-pip.py
RUN pip2.7 install -r requirements.txt
RUN service sshd restart
CMD gunicorn -b 0.0.0.0:8011 application:app 
EXPOSE 8011
