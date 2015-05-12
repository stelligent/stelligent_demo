#!/bin/bash

aws s3 cp s3://nando-automation-demo/cloudformation.stack.name .
echo
stackName=$(< cloudformation.stack.name)
echo $stackName
echo
rm -fv nando-demo.zip
echo
zip nando-demo.zip Dockerfile application.py requirements.txt
echo
aws s3 cp nando-demo.zip s3://nando-automation-demo
echo
/usr/local/bin/eb init -i NandoDemoDockerApp -r us-east-1 -p docker -k ../nando-demo-20150512005231.pem 
echo
/usr/local/bin/eb deploy
