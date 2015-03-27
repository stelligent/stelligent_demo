#!/bin/bash

echo
echo "Nando Automation Demo Launch Script"
echo
keyName="nando-demo"
existingKeypair=$(aws ec2 describe-key-pairs --key-name $keyName) 
if [ ! -z "$existingKeypair" ]; then 
	echo
	echo "Deleting existing $keyName keypair:... $existingKeypair"; 
	aws ec2 delete-key-pair --key-name $keyName
	echo
fi
echo
echo "Creating $keyName keypair:"
echo
privateKeyValue=$(aws ec2 create-key-pair --key-name $keyName)
echo $privateKeyValue
echo

aws cloudformation create-stack --stack-name nando-demo --template-body file://cloudformation.json --parameters ParameterKey=privateKey,ParameterValue=$privateKeyValue
#while (!$(aws cloudformation describe-stacks --stack-name nando-demo|grep CREATE_COMPLETE)); do sleep 10; done
#echo "\n\nThe Demo has been deployed.\n\n"
