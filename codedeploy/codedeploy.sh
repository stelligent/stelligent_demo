#!/bin/bash

commitID=$(git rev-parse --verify HEAD)
echo
echo "using github commit $commitID"
echo
deployID=$(aws deploy create-deployment --application-name nando-demo  --github-location commitId=$commitID,repository=stelligent/nando_automation_demo --deployment-group-name nando-demo)
aws deploy get-deployment --deployment-id $deployID  --query "deploymentInfo.status" --output text
echo

