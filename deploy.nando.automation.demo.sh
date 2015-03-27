#!/bin/bash

echo
echo "Nando Automation Demo Launch Script"
echo
keyName="nando-demo"
existingKeypair=$(aws ec2 describe-key-pairs | cut -f3) 
echo
echo "Ensure $keyName keypair does not exist:"
echo
for thisKeypair in $existingKeypair; do
	echo "testing:... $thisKeypair:$keyName"
	if [[ $thisKeypair == $keyName ]]; then 
		echo "deleting keypair:... $thisKeypair:$keyName"
		aws ec2 delete-key-pair --key-name $keyName
	fi 
done
echo
echo "Creating $keyName keypair:"
echo
keyValue=$(aws ec2 create-key-pair --key-name $keyName)
echo $keyValue
echo

#aws cloudformation create-stack --stack-name nando-demo --template-body  file://cloudformation.json
#while (!$(aws cloudformation describe-stacks --stack-name nando-demo|grep CREATE_COMPLETE)); do sleep 10; done
#echo "\n\nThe Demo has been deployed.\n\n"
