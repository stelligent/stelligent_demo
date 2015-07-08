#!/bin/bash

stackName=$(< "/var/lib/jenkins/cloudformation-stack-name")
bucketName=$(< "/var/lib/jenkins/s3-bucket-name")
rm -fv stelligent-demo.zip
zip stelligent-demo.zip Dockerfile application.py requirements.txt
aws s3 cp stelligent-demo.zip s3://$bucketName
#aws cloudformation create-stack --stack-name $stackName --template-body file://elasticbeanstalk.json
