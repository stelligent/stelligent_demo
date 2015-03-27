#!/bin/bash

clear
echo
echo "Nando Automation Demo Launch Script"
echo
keyName="nando-demo"
cfnFile="file://cloudformation.json"
existingStack=$(aws cloudformation describe-stacks --stack-name $keyName 2> /dev/null)
if [[ $existingStack == *CREATE_COMPLETE* ]]; then 
	echo
	echo "Stack \"$keyName\" exists. Please delete manually before executing this script."
	echo
	echo
	exit 666
fi
existingKeypair=$(aws ec2 describe-key-pairs --key-name $keyName) 
if [ ! -z "$existingKeypair" ]; then 
	echo
	echo "Deleting existing $keyName keypair: $existingKeypair"; 
	aws ec2 delete-key-pair --key-name $keyName
	echo
fi
echo
echo "Creating $keyName keypair:"
echo
privateKeyValue=$(aws ec2 create-key-pair --key-name $keyName)
echo
echo "Launching stack:"
echo
aws cloudformation create-stack --stack-name $keyName --template-body $cfnFile --parameters "ParameterKey=PrivateKey,ParameterValue=$privateKeyValue"

complete=0
second=0
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
	elif [[ $stackStatus != *CREATE_COMPLETE* ]]; then 
		sleep 1; 
		echo -n "."; 
		let seconds=seconds+1
	else 
		echo
		echo $stackStatus
		echo
		complete=1; 
	fi
done
echo
echo
echo "The Demo has been deployed in $seconds seconds."
echo
echo
