# nando_automation_demo



all-in-one automated demo from single cli command

- cloud deployment with cloudformation and auto-scaling

- configuration management with puppet 

- continuous delivery with jenkins

- s3 for static templates, manifests, and encrypted keys



==> ./deploy.nando.automation.demo.sh [TrustedIP1] [TrustedIP2] [TrustedIPX]



This demo launches in an AmazonWebServices VirtualPrivateCloud with one command. One pipeline control box with puppet and jenkins is launched, as well as a webserver AutoScalingGroup tied to an ElasticLoadBalancer, resolved by a Route53 cname alias.  SimpleStorageService is used for authenticated retrieval of static templates, manifests, and encrypted keys for demo, while logs and other output are stored securely. 

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

- Jenkins IAM roles (COMPLETE)
- Ensure latest code on deploy (COMPLETE)
- Layer 4: tcp/ip only from known admin ip/subnets (COMPLETE)
- Layer 7: jenkins application security (COMPLETE)
- Trusted Advisor (PENDING)
- Jenkins Iptables Firewall (PENDING)



# Application Security:

- Private VPC subnet (COMPLETE)
- Application Pen Testing https://github.com/OWASP (PENDING)
- Manual Curl Testing for HTTP responses (PENDING)
- Instance Intrusion Detection https://github.com/ossec/ossec-hids (PENDING)
- Remote Logging (https://github.com/Graylog2 or S3) (PENDING)
- Instance Iptables Firewall (PENDING)



# process_notes

- uploads jenkins templates to S3
- uploads puppet manifests to S3
- creates keypair for use in demo
- launches cfn stack
	- builds vpc and dependancies
	- builds Webserver ASG and ELB with Route53 Alias
	- sets up S3 bucket for all logging and demo output
		- buckey policy restricts access to trusted IPs
		- website indexing is enabled
	- bootstraps jenkins server via cloud init and authenticated S3
		- adds python instagram functionality
		- adds git functionality
		- installs and configures jenkins via puppet
		- pulls jenkins job templates from S3 and creates jenkins jobs
		- jenkins executes based on SCM
			- queries aws for private IPs of web AutoScalingGroup
			- gets instagram images and generates html
			- pushes code and images to staging
			- application and security acceptance testing
			- push to production via ssh on each ASG instance



# todo

- push private key for jenkins from cfn paramater to s3 kms
- 1:1 cfn template to service lifecycle
	- one template for www's, elb, route53, etc
	- one template for jenkins, iam, etc
- add route53 entry for jenkins box via cfn with url as output
- rewrite deploy script in python
- change sleep in cfn-init for instance bootstrap to AWS::CloudFormation::WaitCondition
- update jenkins jobs to python and boto
- use codedeploy or otherwise for jenkins deployments, not ssh

