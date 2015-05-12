#!/bin/bash

stackName="nando-demo-docker-$(date +%Y%m%d%H%M%S)"
rm -fv nando-demo.zip
zip nando-demo.zip Dockerfile application.py requirements.txt
aws s3 cp nando-demo.zip s3://nando-automation-demo
aws s3 cp s://cloudformation-stack-name .
eb init -i NandoDemoDockerApp -k $(cat cloudformation-stack-name)
eb deploy
