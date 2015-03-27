#!/bin/bash

keyName="nando-demo"
cfnFile="file://cloudformation.json"
title="Nando Automation Demo"
clear
echo
echo "$title Launch Script"
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
privateKeyValue=$(aws ec2 create-key-pair --key-name $keyName)
echo
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
echo
echo
echo "$title has deployed in $seconds seconds."
echo
echo
