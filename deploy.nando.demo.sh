#!/usr/bin/bash

aws cloudformation update-stack --stack-name nando-demo --template-body  file://cfn/demo.cfn.json
while (!$(aws cloudformation describe-stacks --stack-name nando-demo|grep CREATE_COMPLETE)); do sleep 10; done
jenkins = $(aws cloudformation describe-stacks --stack-name nando-demo | grep jenkins | cut -f4)
scp -i ~/stelligent/nando_demo.pem ~/stelligent/nando_demo.pem ec2-user@jenkins:
ssh -i ~/stelligent/nando_demo.pem ec2-user@jenkins sudo mv -v nando)demo.pem /var/lib/jenkins
ssh -i ~/stelligent/nando_demo.pem ec2-user@jenkins sudo chown -c jenkins. /var/lib/jenkins/nando_demo.pem
ssh -i ~/stelligent/nando_demo.pem ec2-user@jenkins sudo chmod -c 0400 /var/lib/jenkins/nando_demo.pem
