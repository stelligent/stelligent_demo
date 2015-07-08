#!/bin/bash

REGION="$(wget -q http://169.254.169.254/latest/meta-data/placement/availability-zone -O - | sed -e 's/[a-zA-Z]$//')"
stackName=$(< "/var/lib/jenkins/cloudformation-stack-name")
bucketName=$(< "/var/lib/jenkins/s3-bucket-name")
echo $stackName
echo $bucketName
echo
mkdir ~/.ssh
aws cloudformation describe-stacks --region "${REGION}" --stack-name $stackName|grep PrivateKey -A22|cut -f3 > ~/.ssh/$stackName.pem
chmod 600 ~/.ssh/$stackName.pem
echo
rm -fv stelligent-demo.zip
echo
zip stelligent-demo.zip Dockerfile application.py requirements.txt
echo
aws s3 cp stelligent-demo.zip s3://$bucketName
echo
/usr/local/bin/eb init -i StelligentDemoDockerApp -r "${REGION}" -p docker -k $stackName
echo
/usr/local/bin/eb use StelligentDemoDockerEnvironment
echo
/usr/local/bin/eb deploy
