#!/bin/bash

for job in $(ls -1 /var/lib/jenkins/jobs); do 
	cp -v /var/lib/jenkins/jobs/$job/config.xml /etc/puppet/manifests/job$job.xml.erb; 
done



