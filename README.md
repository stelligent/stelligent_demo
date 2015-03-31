# nando_automation_demo


all-in-one automated demo from single cli command

- cloud deployment with cloudformation

- configuration management with puppet 

- continuous deployment with jenkins

- s3 for static templates, manifests, and encrypted keys


==> ./deploy.nando.automation.demo.sh


This demo launches three instances in a VPC. One command and control box with puppet and jenkins, and two webservers with an ELB in front resolved via route53 cname alias.  The web service serves up "Juxtapo-random": two random instagram images juxtaposed for postmodern study.  Jenkins deploys http://nando-automation-demo.elasticoperations.com, based on SCM of this github repo, updating the images and their layout on the page.  A test suite ensures the images are valid, sized appropriately, tags pass decency tests, and that the image placement makes sense from a UI feng shui perspective.



# process notes

- upload jenkins template to S3
- upload puppet manifests to S3
- create keypair for use in demo
- launch stack and upload www private ip's host file to S3 (cfn outputs)
	- build vpc and dependancies
	- build www instances and ELB with Route53 CNAME Alias
	- build jenkins server
		- add python instagram functionality
		- add git functionality
		- pull jenkins job template from S3 and create jenkins job
		- job executes based on SCM
			- download latest hosts file from S3 (web server private IP list) 
			- get images and generate html and push to staging (jenkins server doubles as staging server)
			- run full acceptance testing suite, including application and environment security tests
			- on success of all tests, push to production


