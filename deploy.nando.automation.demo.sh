#!/usr/bin/bash

aws cloudformation create-stack --stack-name nando-demo --template-body  file://cloudformation.json
while (!$(aws cloudformation describe-stacks --stack-name nando-demo|grep CREATE_COMPLETE)); do sleep 10; done
echo "\n\nThe Demo has been deployed.\n\n"
