# nando_automation_demo



all-in-one automated demo from single cli command

- cloud deployment with cloudformation and auto-scaling

- configuration management with puppet 

- continuous deployment with jenkins

- s3 for static templates, manifests, and encrypted keys



==> ./deploy.nando.automation.demo.sh [TrustedIP1] [TrustedIP2] [TrustedIPX]



This demo launches in an AmazonWebServices VirtualPrivateCloud with one command. One pipeline control box with puppet and jenkins is launched, as well as a webserver AutoScalingGroup tied to an ElasticLoadBalancer, resolved by a Route53 cname alias.  SimpleStorageService is used to store static templates, manifests, and encrypted keys. 

The web service serves up "Juxtapo-random": two random instagram images juxtaposed for postmodern study.  Jenkins deploys http://nando-automation-demo.elasticoperations.com, based on SourceControlManagement of this github repo, updating the images and their layout on the page.  

Acceptance tests ensure the images are valid, sized appropriately, tags pass decency tests, and that the image placement makes sense from a UserInterface feng shui perspective. Security tests ensure the application has been deployed securely.



# Pipeline Blueprint

- deploy-pipeline-1-command (bash script launches all cfn resources except unsupported ec2::create-keypair)
- provision-environment (cloudformation, bash)
- node-configuration (packages, files, services)
- poll-version-control (github every minute https://github.com/stelligent/nando_automation_demo)
- app-deployment: (jenkins, plugins, and jobs installed by puppet with erb templates)



# Pipeline Pending:

- node-configuration: data encryption
- node-configuration: security hardening
- node-configuration: test db and local tests
- configure-local-environment-1-command: vagrant
- run-application-build: (Rake, Maven, Ant, Grunt)
- store-distros: (Nexus, Artifactory, S3)
- run-unit-tests: (RSpec, JUnit, XUnit)
- run-static-analysis: (CheckStyle, PMD, Sonar, CodeClimate, JSONLint, ValidateTemplate, ratproxy, Foodcritic)
- app-deployment: (Chef, Puppet, Ansible, CodeDeploy)
- run-infrastructure-tests: (ServerSpec, Cucumber)
- poll-version-control (puppet, jenkins modules)



# Pipeline Security:

- Trusted Advisor 
- IAM roles
- Ensure latest code
- Layer 4: tcp/ip only from known admin ip/subnets
- Layer 7: jenkins matrix user security
- Instance Firewall (iptables)



# Application Security:

- Application Pen Testing https://github.com/OWASP
- Manual Tests (curl testing for HTTP methods, etc)
- Instance Intrusion Detection https://github.com/ossec/ossec-hids
- Remote Logging (https://github.com/Graylog2)
- Private VPC subnet
- Instance Firewall (iptables)



# process_notes

- uploads jenkins template to S3
- uploads puppet manifests to S3
- creates keypair for use in demo
- launches cfn stack
	- builds vpc and dependancies
	- builds Webserver ASG and ELB with Route53 Alias
	- sets up S3 bucket for all logging
	- bootstraps jenkins server via cloud init and authenticated S3
		- adds python instagram functionality
		- adds git functionality
		- installs and configures jenkins via puppet
		- pulls jenkins job template from S3 and creates jenkins job
		- job executes based on SCM
			- queries aws for private IPs of web AutoScalingGroup
			- gets instagram images and generates html
			- pushes code and images to staging
			- application and security acceptance testing
			- push to production via ssh on each ASG instance



# todo

- move instance bootstrap from user-data to meta-data in cfn
- push private key for jenkins from cfn paramater to s3 kms
- 1:1 cfn template to service lifecycle
	- one template for www's, elb, route53, etc
	- one template for jenkins, iam, etc
- add route53 entry for jenkins box via cfn with url as output
- rewrite deploy script in python
- change sleep in cfn-init for instance bootstrap to AWS::CloudFormation::WaitCondition
- update jenkins job to python and boto

