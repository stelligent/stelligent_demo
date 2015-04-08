# nando_automation_demo



All-in-one automated demo from single cli command.

- Cloud deployment with CloudFormation

- Configuration management with Puppet 

- Continuous delivery with Jenkins and CodeDeploy

- High availability with ELB and ASG

- S3 for static templates, manifests, encrypted keys, and demo outputs.

- IAM and S3 roles and policies for security


==> ./deploy.nando.automation.demo.sh [TrustedIP1] [TrustedIP2] [TrustedIPX]



This demo launches in an AmazonWebServices VirtualPrivateCloud with one command. One pipeline control box with puppet and jenkins is launched, as well as a webserver AutoScalingGroup tied to an ElasticLoadBalancer, resolved by a Route53 cname alias. SimpleStorageService is used for authenticated retrieval of static templates, manifests, and encrypted keys needed upon bootstrap. S3 is also used for the running demo to store logs and other outputs securely. 

The web service serves up "Juxtapo-random": two random instagram images juxtaposed for postmodern study.  Jenkins delivers http://nando-automation-demo.elasticoperations.com, based on SourceControlManagement of this github repo.  

Acceptance tests ensure the images are valid, sized appropriately, tags pass decency tests, and that the image placement makes sense from a UserInterface feng shui perspective. Security tests ensure the application has been deployed securely.



# Pipeline Blueprint (COMPLETE)

- deploy-pipeline-1-command (CFN template launches all resources except unsupported EC2::Create-Keypair and CodeDeploy)
- provision-environment (cloudformation, bash)
- node-configuration (packages, files, services)
- poll-version-control (github every minute https://github.com/stelligent/nando_automation_demo)
- app-deployment: (CodeDeploy)



# Pipeline Blueprint (PENDING):

- node-configuration: data encryption
- node-configuration: security hardening
- node-configuration: test db and local tests
- configure-local-environment-1-command: vagrant
- run-application-build: (Rake, Maven, Ant, Grunt)
- store-distros: (Nexus, Artifactory, S3)
- run-unit-tests: (RSpec, JUnit, XUnit)
- run-static-analysis: (CheckStyle, PMD, Sonar, CodeClimate, JSONLint, ValidateTemplate, ratproxy, Foodcritic)
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
		- pulls jenkins job templates from authenticated S3 and creates jenkins jobs
		- jenkins executes based on SCM
			- queries aws for private IPs of web AutoScalingGroup
			- gets instagram images and generates html
			- pushes code and images to staging (pending)
			- application and security acceptance testing (pending)
			- push to production with CodeDeploy



# todo

- push private key for jenkins from cfn paramater to s3 kms
- 1:1 cfn template to service lifecycle
	- one template for www's, elb, route53, etc
	- one template for jenkins, iam, etc
- add route53 entry for jenkins box via cfn with url as output
- rewrite deploy script in python
- change sleep in cfn-init for instance bootstrap to AWS::CloudFormation::WaitCondition
- update jenkins jobs to python and boto

