#!/bin/bash

asg="nando-demo-20150408150144-NandoDemoWebASG-W567NRZGRCHA"

#aws deploy create-application --application-name nando-demo

echo
echo "delete existing role and policy"
echo
aws iam delete-role-policy --role-name NandoDemoCodeDeployRole --policy-name NandoDemoCodeDeployPolicy 2> /dev/null
aws iam delete-role --role-name NandoDemoCodeDeployRole 2> /dev/null
sleep 1
echo
echo "create codedeploy role and policy"
echo
aws iam create-role --role-name NandoDemoCodeDeployRole --assume-role-policy-document file://codedeploy/NandoDemoCodeDeployRole.json
sleep 2
aws iam put-role-policy --role-name NandoDemoCodeDeployRole --policy-name NandoDemoCodeDeployPolicy --policy-document file://codedeploy/NandoDemoCodeDeployPolicy.json
sleep 2
echo
echo "Create codedeploy deployment-group"
echo
roleArn=$(aws iam get-role --role-name NandoDemoCodeDeployRole --query "Role.Arn" --output text)
aws deploy delete-deployment-group --application-name nando-demo --deployment-group-name nando-demo 2> /dev/null
aws deploy create-deployment-group --application-name nando-demo --deployment-group-name nando-demo --service-role-arn $roleArn --auto-scaling-group $asg
sleep 1
echo
echo "get codedeploy deployment ID"
echo
deployID=$(aws deploy create-deployment --application-name nando-demo  --github-location commitId=5816419ce6eeb3b4dd996297773cfe83f50c1488,repository=stelligent/nando_automation_demo --deployment-group-name nando-demo)
echo
echo "get $deployID status"
echo
aws deploy get-deployment --deployment-id $deployID  --query "deploymentInfo.status" --output text
echo
