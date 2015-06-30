#!/bin/bash

stackName="stelligent-demo-docker-$(date +%Y%m%d%H%M%S)"
rm -fv stelligent-demo.zip
zip stelligent-demo.zip Dockerfile application.py requirements.txt
aws s3 cp stelligent-demo.zip s3://stelligent-demo
#aws cloudformation create-stack --stack-name $stackName --template-body file://elasticbeanstalk.json
