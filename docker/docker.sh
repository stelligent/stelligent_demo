#!/bin/bash

rm -fv nando-demo.zip
zip nando-demo.zip Dockerfile application.py requirements.txt
aws s3 cp nando-demo.zip s3://nando-automation-demo
aws cloudformation create-stack --stack-name nando-demo-docker --template-body file://elasticbeanstalk.json
