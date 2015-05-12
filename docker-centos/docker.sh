#!/bin/bash

stackName="nando-demo-docker-$(date +%Y%m%d%H%M%S)"
rm -fv nando-demo.zip
zip nando-demo.zip Dockerfile application.py requirements.txt
aws s3 cp nando-demo.zip s3://nando-automation-demo
aws s3 cp s3://cloudformation-stack-name .
/usr/local/bin/eb init -i NandoDemoDockerApp -r us-east-1 -p docker -k ../nando-demo-20150512005231.pem 
/usr/local/bin/eb deploy
