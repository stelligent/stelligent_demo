#!/bin/bash

aws s3 cp s3://nando-automation-demo/cloudformation.stack.name .
echo
stackName=$(< cloudformation.stack.name)
echo $stackName
echo
aws cloudformation describe-stacks --region us-east-1 --stack-name $stackName|grep PrivateKey -A22|cut -f3 > ~/.ssh/$stackName.pem
echo
rm -fv nando-demo.zip
echo
zip nando-demo.zip Dockerfile application.py requirements.txt
echo
aws s3 cp nando-demo.zip s3://nando-automation-demo
echo
/usr/local/bin/eb init -i NandoDemoDockerApp -r us-east-1 -p docker -k $stackName
echo
/usr/local/bin/eb deploy
