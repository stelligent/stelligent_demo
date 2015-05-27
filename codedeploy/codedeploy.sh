#!/bin/bash

REGION="$(wget -q http://169.254.169.254/latest/meta-data/placement/availability-zone -O - | sed -e 's/[a-zA-Z]$//')"
commitID=$(git rev-parse --verify HEAD)
echo
echo "using github commit $commitID"
echo

aws iam create-role --role-name NandoDemoCodeDeployRole --assume-role-policy-document file://codedeploy/NandoDemoCodeDeployRole.json 2> /dev/null || true
aws iam put-role-policy --role-name NandoDemoCodeDeployRole --policy-name NandoDemoCodeDeployPolicy --policy-document file://codedeploy/NandoDemoCodeDeployPolicy.json 2> /dev/null || true
roleArn=$(aws iam get-role --role-name NandoDemoCodeDeployRole --query "Role.Arn" --output text)

aws deploy get-application --region "${REGION}" --application-name nando-demo || \
{
    aws deploy create-application --application-name nando-demo --region "${REGION}"
}

aws deploy get-deployment-group --application-name nando-demo --deployment-group-name nando-demo --region "${REGION}" || \
{
    aws deploy create-deployment-group --application-name nando-demo --deployment-group-name nando-demo  --region "${REGION}" --service-role-arn "${roleArn}"
}

deployID=$(aws deploy create-deployment --output text --region "${REGION}" --application-name nando-demo  --github-location commitId=$commitID,repository=stelligent/nando_automation_demo --deployment-group-name nando-demo)
echo
aws deploy get-deployment --region "${REGION}" --deployment-id $deployID  --query "deploymentInfo.status" --output text
echo

