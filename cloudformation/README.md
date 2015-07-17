# Stelligent Demo CloudFormation Templates

These are the individual components to the Stelligent Demo CloudFormation templates.  Currently these are broken down in to:

cloudformation.asg.json
cloudformation.eb.json
cloudformation.ecs.json
cloudformation.jenkins.json
cloudformation.rds.json
cloudformation.s3.json
cloudformation.sg.json
cloudformation.vpc.json

## AutoScaling Group

## ElasticBeanstalk

## EC2 Container Service

The ECS service is fairly independent of the rest of the Stelligent Demo.  It relies only on the VPC and a small subset of the Security Groups.  The ECS architecture is designed to create an ECS cluster that is bound to an ASG for managing the ECS instances which are getting routed data via an ELB.  

Docker is implemented by creating an image from a Dockerfile.  The container created is a simple apache service that servers a static webpage.  The UserData portion of the CFN template pulls down a zip file containing the Dockerfile and webpage, uncompresses and builds the Docker image.  It handles all this in a temp directory that is deleted once the process is completed.

```bash
yum -y install aws-cli unzip
export TMP=$(/bin/mktemp -d)
pushd $TMP
aws --region $(AWS_REGION) s3 cp s3://$(EPHEMERAL_S3_BUCKET)/stelligent-demo.zip .
unzip stelligent-demo.zip
docker build -t stelligent/stelligent-demo-docker-image:latest .
popd && rm -rf $TMP
```

The reason the Docker image is handled in this manner is because there is currently no publicly accessable Stelligent Docker registry.  Using or creating a private registry would prevent the Stelligent Demo from being portable amongst AWS accounts.

Once the image is built and tagged, it can be seen in Docker on the ECS instance:

```
[ec2-user@ip-10-200-0-32 ~]$ docker images
REPOSITORY                                TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
stelligent/stelligent-demo-docker-image   latest              05b545320fdb        7 minutes ago       642.9 MB
amazon/amazon-ecs-agent                   latest              edda11aee701        3 weeks ago         8.256 MB

```

The image name can now be specified via the CFN ECS template:

```
          "Image": { "Fn::Join": [ "/", [                                       
            { "Ref": "StelligentDemoDockerRegistryLabel" },                     
            { "Ref": "StelligentDemoDockerImage" }                              
          ]]},
```

The zip file mentioned above, 'stelligent-demo.zip' is created from the go.py script when the stack is built.  In the go.py script is a list variable, 'DOCKER_FILES', this contains a string list of all the files to include in the zip file found in the Git repository sub-directory named '~/docker'.  Once the go script creates the zip archive, it uploads it to the ephemeral S3 bucket.  

The Docker image is based off CentOS 6 and will run Apache on port 8011.  The ELB is mapping the ECS instance port 8011 to port 80.  While a shared volume is specified in the CFN, it is not necessary.  Additionally, an ASG is specified but is currently set to a minimum of 1 instance and a max of 2. 

### Additional Docker Image Method (local registry server S3-backed repository)_

Another method for managing our Docker container is to create an S3 backed repostory on the EC2 container instance.  Since the S3 bucket is already configured with a registry containing an image.  An S3 registry has been created in:

```
s3://stelligent-demo-docker-repo/registry
```

The registry gets created on the local machine and the resgistry service runs from a container there.  It's simply configured to use S3 to store it's registry data versus the local filesystem.  An S3 backed registry can be created with the following command:

```
docker run -e SETTINGS_FLAVOR=s3 -e AWS_BUCKET=stelligent-demo-docker-repo -e STORAGE_PATH=/registry -e AWS_KEY=<access_key> -e AWS_SECRET=<secret_key> -e SEACH_BACKEND=sqlalchemy -p 5000:5000 --name registry -d registry
```

That will start up a registry container named 'registry' that listens on localhost port 5000.  The image needs to be created and added.  This can be done by creating the image, pushing it into the registry and optionally, tagging it:

```
export IMAGE=$(docker build . | tail -1 | awk '{print $NF}')
docker push localhost:5000/${IMAGE}
docker tag ${IMAGE} localhost:5000/stelligent-demo-docker-image:latest
```

To add this method to the CFN the UserData lines above need to be replaced with the docker registry creation line above.  This method will take a few moments longer as it will need to pull down the Docker registery container before it can access the stelligent-demo-docker-image.

The reason I did not continue with this method is because Docker requires the AWS access and secret keys on the command line to access the S3 bucket, regardless of the IAM Role associated with the EC2 instance.  At this time I believe this is not the best solution given the alternative.

## Jenkins

## Relational Database Service (RDS)

## Simple Storage Service (S3)

## Security Groups

## Virtual Private Cloud
