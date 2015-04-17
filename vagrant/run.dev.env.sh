#!/bin/bash

rm -rf puppetmods
mkdir -v puppetmods
git clone https://github.com/jenkinsci/puppet-jenkins.git puppetmods/jenkins

vagrant reload --provision

