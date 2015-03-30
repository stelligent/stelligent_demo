#!/bin/bash

keyName="nando-demo"
cfnFile="file://cloudformation.json"
title="Nando Automation Demo"
clear
echo
echo "$title Launch Script"
echo
if [ "$1" ==  "delete" ]; then
	echo
	echo "DELETE MODE.  Deleting stack: \"$keyName\"."
	echo
	aws cloudformation delete-stack --stack-name $keyName
	echo
	exit
fi 
existingStack=$(aws cloudformation describe-stacks --stack-name $keyName 2> /dev/null)
if [[ $existingStack == *CREATE_COMPLETE* ]]; then 
	echo
	echo "Stack \"$keyName\" exists. Please delete manually before executing this script."
	echo
	echo
	exit 666
fi
if [[ $existingStack == *DELETE_IN_PROGRESS* ]]; then 
	echo
	echo "Stack \"$keyName\" is deleting.  Please wait until deletion is complete before running this script."
	echo
	echo
	exit 666
fi
if [[ $existingStack == *CREATING_IN_PROGRESS* ]]; then
        echo
        echo "Stack \"$keyName\" is creating.  Please wait until deletion is complete before running this script."
        echo
        echo
        exit 666
fi
echo "Upload Files to S3"
s3cmd put jenkins.xml.erb s3://nando-automation-demo --add-header=x-amz-acl:public-read
s3cmd put installmodulegit.pp s3://nando-automation-demo --add-header=x-amz-acl:public-read
s3cmd put installmodulepython.pp s3://nando-automation-demo --add-header=x-amz-acl:public-read
s3cmd put installjenkins.pp s3://nando-automation-demo --add-header=x-amz-acl:public-read
s3cmd put installjob.pp s3://nando-automation-demo --add-header=x-amz-acl:public-read 
echo
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

#echo "create s3 role for jenkins instance:"
# Create the role and attach the trust policy that enables EC2 to assume this role.
#aws iam create-role --role-name Test-Role-for-EC2 --assume-role-policy-document file://C:\policies\trustpolicyforec2.json
# Attach the permissions policy to the role to specify what it is allowed to do.
#aws iam put-role-policy --role-name Test-Role-for-EC2 --policy-name Permissions-Policy-For-Ec2 --policy-document file://c:\policies\permissionspolicyforec2.json
# Create the instance profile required by EC2 to contain the role
#aws iam create-instance-profile --instance-profile-name EC2-ListBucket-S3
## Finally, add the role to the instance profile
#aws iam add-role-to-instance-profile --instance-profile-name EC2-ListBucket-S3 --role-name Test-Role-for-EC2

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
s3cmd put hosts s3://nando-automation-demo --add-header=x-amz-acl:public-read 
echo
echo
echo
echo "$title has deployed in $seconds seconds."
echo
echo
