#!/bin/bash

keyName="nando-demo"
cfnFile="file://cloudformation.json"
title="Nando Automation Demo"
clear
echo
echo "$title Launch Script"
echo
echo "Upload Files to S3"
s3cmd put jenkins.xml.erb s3://nando-automation-demo --add-header=x-amz-acl:authenticated-read
s3cmd put installjenkins.pp s3://nando-automation-demo --add-header=x-amz-acl:authenticated-read
s3cmd put installjob.pp s3://nando-automation-demo --add-header=x-amz-acl:authenticated-read 
echo
existingStack=$(aws cloudformation describe-stacks --stack-name $keyName 2> /dev/null)
if [[ $existingStack == *CREATE_COMPLETE* ]]; then 
	echo
	echo "Stack \"$keyName\" exists. Please delete manually before executing this script."
	echo
	echo
	exit 666
fi
existingKeypair=$(aws ec2 describe-key-pairs --key-name $keyName 2> /dev/null) 
if [[ $existingKeypair == *$keyName* ]]; then 
	echo
	echo "Deleting existing $keyName keypair: $existingKeypair"; 
	aws ec2 delete-key-pair --key-name $keyName
	echo
fi
echo
echo "Creating $keyName private key as $keyName.pem ."
privateKeyValue=$(aws ec2 create-key-pair --key-name $keyName --query 'KeyMaterial' --output text)
echo
if [ -f "$keyName.pem" ]; then chmod -v u+w nando-demo.pem; fi
echo $privateKeyValue > $keyName.pem
ls -la $keyName.pem
echo
echo
echo
echo "Launching stack:"
echo
aws cloudformation create-stack --stack-name $keyName --template-body $cfnFile --parameters "ParameterKey=PrivateKey,ParameterValue=$privateKeyValue"
complete=0
while [ "$complete" -ne 1 ]; do
	stackStatus=$(aws cloudformation describe-stacks --stack-name $keyName)
	if [[ $stackStatus == *ROLLBACK* ]]; then
		echo
		echo "FAILURE"
		echo
		echo $stackStatus
		echo
		echo
		exit 666
	elif [[ $stackStatus == *CREATE_COMPLETE* ]]; then 
		echo
		echo $stackStatus
		echo
		complete=1; 
	else 
		sleep 1; 
		echo -n "."; 
		let seconds=seconds+1
	fi
done
echo
echo "Create hosts file:"
aws cloudformation describe-stacks --stack-name $keyName|grep ww1PrivateIP|cut -f4 > hosts
aws cloudformation describe-stacks --stack-name $keyName|grep ww2PrivateIP|cut -f4 >> hosts
cat hosts
echo
echo "Upload hosts:"
jenkinsPublicIP=$(aws cloudformation describe-stacks --stack-name $keyName|grep jenkinsPublicIP|cut -f4)
scp -i nando-demo.pem hosts ec2-user@$jenkinsPublicIP
echo
echo
echo
echo "$title has deployed in $seconds seconds."
echo
echo
