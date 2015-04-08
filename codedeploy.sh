#!/bin/bash

aws deploy create-application --application-name nando-demo
aws iam create-role --role-name NandoDemoCodeDeploy --assume-role-policy-document file://codedeploy/NandoDemoCodeDeployRole.json
aws iam put-role-policy --role-name NandoDemoCodeDeploy --policy-name NandoDemoCodeDeployPolicy --policy-document file://codedeploy/NandoDemoCodeDeployPolicy.json

arn=$(aws iam get-role --role-name NandoDemoCodeDeploy --query "Role.Arn" --output text)
aws deploy create-deployment-group --application-name nando-demo --deployment-group-name nando-demo --service-role-arn $arn
$deploy=$(aws deploy create-deployment --application-name nando-demo  --github-location commitId=894480a5138df47b82bb493b81944631fda5362f,repository=stelligent/nando-automation-demo --deployment-group-name nando-demo)
