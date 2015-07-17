FROM centos:6
MAINTAINER The CentOS Project <cloud-ops@centos.org> - ami_creator
RUN yum -y update 
RUN yum -y install wget tar curl openssh-server httpd epel-release
RUN sed -i 's/^Listen 80$/Listen 8011/' /etc/httpd/conf/httpd.conf
ADD . /var/www/html
RUN service sshd restart
EXPOSE 8011
