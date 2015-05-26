#!/bin/bash

REGION="$(wget -q http://169.254.169.254/latest/meta-data/placement/availability-zone -O - | sed -e 's/[a-zA-Z]$//')"
aws s3 cp "s3://nando-automation-demo/cloudformation.stack.name-${REGION}" .
echo
stackName=$(< "cloudformation.stack.name-${REGION}")
echo $stackName
echo
aws cloudformation describe-stacks --region "${REGION}" --stack-name $stackName|grep PrivateKey -A22|cut -f3 > ~/.ssh/$stackName.pem
echo
rm -fv nando-demo.zip
echo
zip nando-demo.zip Dockerfile application.py requirements.txt
echo
aws s3 cp nando-demo.zip s3://nando-automation-demo
echo
/usr/local/bin/eb init -i NandoDemoDockerApp -r "${REGION}" -p docker -k $stackName
echo
/usr/local/bin/eb use NandoDemoDockerEnvironment
echo
/usr/local/bin/eb deploy
