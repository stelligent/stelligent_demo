#!/bin/bash

REGION="$(wget -q http://169.254.169.254/latest/meta-data/placement/availability-zone -O - | sed -e 's/[a-zA-Z]$//')"
ARN="$(aws iam list-roles | grep -i Arn.*CodeDeploy.*$REGION | sed -e 's/.*: "\(.*\)"/\1/')"
commitID=$(git rev-parse --verify HEAD)
echo
echo "using github commit $commitID"
echo


aws deploy get-application --region "${REGION}" --application-name nando-demo || \
{
    aws deploy create-application --application-name nando-demo --region "${REGION}"
}

aws deploy get-deployment-group --application-name nando-demo --deployment-group-name nando-demo --region "${REGION}" || \
{
    aws deploy create-deployment-group --application-name nando-demo --deployment-group-name nando-demo  --region "${REGION}" --service-role-arn "${ARN}"
}

deployID=$(aws deploy create-deployment --output text --region "${REGION}" --application-name nando-demo  --github-location commitId=$commitID,repository=stelligent/nando_automation_demo --deployment-group-name nando-demo)
echo
aws deploy get-deployment --region "${REGION}" --deployment-id $deployID  --query "deploymentInfo.status" --output text
echo

