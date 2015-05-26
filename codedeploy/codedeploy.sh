#!/bin/bash

REGION="$(wget -q http://169.254.169.254/latest/meta-data/placement/availability-zone -O - | sed -e 's/[a-zA-Z]$//')"
commitID=$(git rev-parse --verify HEAD)
echo
echo "using github commit $commitID"
echo

aws deploy list-applications --region "${REGION}" --application-name nando-demo || \
{
    aws deploy create-application --application-name nando-demo --region "${REGION}"
}

deployID=$(aws deploy create-deployment --output text --region "${REGION}" --application-name nando-demo  --github-location commitId=$commitID,repository=stelligent/nando_automation_demo --deployment-group-name nando-demo)
echo
aws deploy get-deployment --region "${REGION}" --deployment-id $deployID  --query "deploymentInfo.status" --output text
echo

