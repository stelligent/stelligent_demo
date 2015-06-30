#!/bin/bash

REGION="$(wget -q http://169.254.169.254/latest/meta-data/placement/availability-zone -O - | sed -e 's/[a-zA-Z]$//')"
commitID=$(git rev-parse --verify HEAD)
echo
echo "using github commit $commitID"
echo

aws iam create-role --role-name StelligentDemoCodeDeployRole --assume-role-policy-document file://codedeploy/StelligentDemoCodeDeployRole.json 2> /dev/null || true
aws iam put-role-policy --role-name StelligentDemoCodeDeployRole --policy-name StelligentDemoCodeDeployPolicy --policy-document file://codedeploy/StelligentDemoCodeDeployPolicy.json 2> /dev/null || true
roleArn=$(aws iam get-role --role-name StelligentDemoCodeDeployRole --query "Role.Arn" --output text)

aws deploy get-application --region "${REGION}" --application-name stelligent-demo || \
{
    aws deploy create-application --application-name stelligent-demo --region "${REGION}"
}

aws deploy get-deployment-group --application-name stelligent-demo --deployment-group-name stelligent-demo --region "${REGION}" || \
{
    aws deploy create-deployment-group --application-name stelligent-demo --deployment-group-name stelligent-demo  --region "${REGION}" --service-role-arn "${roleArn}"
}

deployID=$(aws deploy create-deployment --output text --region "${REGION}" --application-name stelligent-demo  --github-location commitId=$commitID,repository=stelligent/stelligent_demo --deployment-group-name stelligent-demo)
echo
aws deploy get-deployment --region "${REGION}" --deployment-id $deployID  --query "deploymentInfo.status" --output text
echo

