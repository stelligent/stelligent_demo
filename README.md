# nando_automation_demo
nando_automation_demo


all-in-one automated demo from single cli command

- cloud deployment with cloudformation

- configuration management with puppet 

- continuous deployment with jenkins

- s3 for static templates, manifests, and encrypted keys


==> ./deploy.nando.automation.demo.sh


This demo launches two instances in a VPC with an ELB in front.  A web service is initiated and serves up "Juxtapo-random": two random instagram images, created within the last 300 seconds, juxtaposed for postmodern study.  Jenkins continually deploys the website every 5 minutes, updating the images and their layout on the page.  A test suite ensures the images are valid, sized appropriately, tags pass decency tests, and that the image placement makes sense from a UI feng shui perspective.


