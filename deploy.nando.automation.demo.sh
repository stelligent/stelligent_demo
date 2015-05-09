#!/bin/bash

keyName="nando-demo-$(date +%Y%m%d%H%M%S)"
cfnFile="file://cloudformation.json"
title="Nando Automation Demo"
clear
echo
echo "$title $keyName Launch Script"
echo
if [ "$1" ==  "delete" ]; then
        echo
        echo "DELETE MODE.  Deleting stack: \"$keyName\"."
        echo
        aws cloudformation delete-stack --stack-name $keyName
        echo "waiting on delete stack $keyName ."
	sleep 5
        echo
	complete=0
	seconds=0
	while true; do
        	stackStatus=$(aws cloudformation describe-stacks --stack-name $keyName 2> /dev/null)
        	if [[ $stackStatus == *DELETE_IN_PROGRESS* ]]; then
                	echo -n ".";
                	sleep 1;
                	let seconds=seconds+1
        	else
                	echo
                	echo $stackStatus
                	echo
			echo "Stack $keyName deleted in $seconds seconds"
			echo
			echo
			exit
        	fi
	done
fi
numLocationsExpected=$(grep "Location.\" :" cloudformation.json | wc -l)
if [ "$numLocationsExpected" -ne "$#" ]; then
	echo
	echo "expected $numLocationsExpected and number provided is $#"
	echo
	exit 666
fi
ipcount=0
echo "Secure locations (for ssh and jenkins) are: "
for ip in "$@"; do
	if [[ ! $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then 
		echo
		echo "invalid IP: $ip"; 
		echo
		exit 666
	else
		echo -n " $ip "
		let ipcount=$ipcount+1
		cfnParameters+=" ParameterKey=Location$ipcount,ParameterValue=\"$ip/32\" "
	fi
done
echo
echo
existingStack=$(aws cloudformation describe-stacks --stack-name $keyName 2> /dev/null)
if [[ $existingStack == *CREATE_COMPLETE* ]]; then 
	echo
	echo "Stack \"$keyName\" exists. Please delete manually before executing this script."
	echo
	echo $existingStack
	echo
	echo
	exit 666
fi
if [[ $existingStack == *ROLLBACK* ]]; then
        echo
        echo "Stack \"$keyName\" is in Rollback Mode. Please delete manually before executing this script."
        echo
	echo $existingStack
	echo
        echo
        exit 666
fi
if [[ $existingStack == *DELETE_IN_PROGRESS* ]]; then 
	echo
	echo "Stack \"$keyName\" is deleting.  Please wait until deletion is complete before running this script."
	echo
	echo $existingStack
	echo
	echo
	exit 666
fi
if [[ $existingStack == *CREATING_IN_PROGRESS* ]]; then
        echo
        echo "Stack \"$keyName\" is creating.  Please wait until creation is complete or delete stack before running this script."
        echo
	echo $existingStack
	echo
        echo
        exit 666
fi
echo
echo
echo "Upload Files to S3"
echo
aws s3 cp puppet/jobCodeDeployProduction.xml.erb s3://nando-automation-demo
aws s3 cp puppet/jobCodeDeployStageTests.xml.erb s3://nando-automation-demo
aws s3 cp puppet/jobCodeDeployStage.xml.erb s3://nando-automation-demo
aws s3 cp puppet/jobDockerDeployProduction.xml.erb s3://nando-automation-demo
aws s3 cp puppet/jobDockerDeployStageTests.xml.erb s3://nando-automation-demo
aws s3 cp puppet/jobDockerDeployStage.xml.erb s3://nando-automation-demo
aws s3 cp puppet/jobInstagramImageGet.xml.erb s3://nando-automation-demo
aws s3 cp puppet/jobInstagramImageSave.xml.erb s3://nando-automation-demo
aws s3 cp puppet/jobInstagramImageTest.xml.erb s3://nando-automation-demo
aws s3 cp puppet/installJenkins.pp s3://nando-automation-demo
aws s3 cp puppet/installJenkinsJob.pp s3://nando-automation-demo 
aws s3 cp puppet/installJenkinsPlugins.pp s3://nando-automation-demo 
aws s3 cp puppet/installJenkinsUsers.pp s3://nando-automation-demo 
aws s3 cp puppet/installJenkinsSecurity.pp s3://nando-automation-demo 
cd docker
rm -fv nando-demo.zip
zip nando-demo.zip Dockerfile application.py requirements.txt
aws s3 cp nando-demo.zip s3://nando-automation-demo
cd ..

echo
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
cfnParameters+=" ParameterKey=NandoDemoName,ParameterValue=$keyName ParameterKey=KeyName,ParameterValue=$keyName "
echo
instagramId=$(env|grep INSTAGRAM_CLIENT_ID |cut -f2 -d=)
instagramSecret=$(env|grep INSTAGRAM_CLIENT_SECRET |cut -f2 -d=)
if [ -z "$instagramId" ] || [ -z "$instagramSecret" ]; then 
	echo 
	echo "you must set INSTAGRAM_CLIENT_ID and INSTAGRAM_CLIENT_SECRET environment variables."
	echo
	echo
	exit
fi
cfnParameters+=" ParameterKey=InstagramId,ParameterValue=$instagramId ParameterKey=InstagramSecret,ParameterValue=$instagramSecret "
echo
echo
echo "Launching stack:"
echo
echo $cfnParameters
echo
aws cloudformation create-stack --capabilities CAPABILITY_IAM --stack-name $keyName --template-body $cfnFile --parameters "ParameterKey=PrivateKey,ParameterValue=$privateKeyValue" $cfnParameters
echo
complete=0
seconds=0
while [ "$complete" -ne 1 ]; do
	stackStatus=$(aws cloudformation describe-stacks --stack-name $keyName 2> /dev/null)
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
		if [[ $seconds%10 -eq 0 ]]; then echo -n $seconds; 
		else echo -n "."; fi
		let seconds=seconds+1
	fi
done
echo
echo
echo
echo "Write out private key $keyName.pem ."
rm -fv $keyName.pem
aws cloudformation describe-stacks --stack-name $keyName|grep PrivateKey -A22|cut -f3 > $keyName.pem



# if osx
chmod -v 0400 $keyName.pem
# if linux
#chmod -c 0400 $keyName.pem



echo
s3bucket=$(aws cloudformation describe-stacks --stack-name $keyName | grep -v URL | grep -v CNAME | grep NandoDemoBucket | cut -f3)
echo "upload index.html to s3 bucket $s3bucket"
aws s3 cp s3/index.html s3://$s3bucket
echo
jenkinsIP=$(aws cloudformation describe-stacks --stack-name $keyName | grep NandoDemoJenkinsEIP | cut -f3)
echo "ssh -i $keyName.pem ec2-user@$jenkinsIP"
echo
echo "$title has deployed in $seconds seconds."
echo
echo
echo
echo "Launching CodeDeploy:"
echo
echo
aws deploy create-application --application-name nando-demo 2> /dev/null
aws iam create-role --role-name NandoDemoCodeDeployRole --assume-role-policy-document file://codedeploy/NandoDemoCodeDeployRole.json 2> /dev/null
aws iam put-role-policy --role-name NandoDemoCodeDeployRole --policy-name NandoDemoCodeDeployPolicy --policy-document file://codedeploy/NandoDemoCodeDeployPolicy.json 2> /dev/null
roleArn=$(aws iam get-role --role-name NandoDemoCodeDeployRole --query "Role.Arn" --output text)
asgName=$(aws cloudformation describe-stacks | grep NandoDemoWebASG | cut -f3 | head -1)
aws deploy delete-deployment-group --application-name nando-demo --deployment-group-name nando-demo 2> /dev/null
sleep 2
aws deploy create-deployment-group --application-name nando-demo --deployment-group-name nando-demo --service-role-arn $roleArn --auto-scaling-group $asgName
commitID=$(git rev-parse --verify HEAD)
deployID=$(aws deploy create-deployment --application-name nando-demo  --github-location commitId=$commitID,repository=stelligent/nando_automation_demo --deployment-group-name nando-demo)
aws deploy get-deployment --deployment-id $deployID  --query "deploymentInfo.status" --output text
echo
echo
