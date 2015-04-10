#!/bin/bash

rm -fv docker/nando-demo.zip
zip docker/nando-demo.zip docker/Dockerfile docker/application.py docker/requirements.txt
aws s3 cp docker/nando-demo.zip s3://nando-automation-demo
aws cloudformation create-stack --stack-name nando-demo-docker --template-body file://docker/elasticbeanstalk.json
