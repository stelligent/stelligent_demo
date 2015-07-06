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

Docker was implemented by pulling the stelligent demo image from S3 and inserting the image directly into the local docker registry.  This is handled in the UserData portion of the CFN template for the EC2 container instance.  This is what is currently used to import the Docker image from S3 on the instance, a policy is in place allowing access to the S3 bucket:

```bash
aws s3 cp s3://stelligent-demo-docker-repo/stelligent-demo-docker.image.tar - \
 | gunzip | docker load
docker tag stelligent-demo-docker-image stelligent/05b545320fdb
```

Once properly loaded and tagged it can be seen in Docker:

```
          "Image": { "Fn::Join": [ "/", [                                       
            { "Ref": "StelligentDemoDockerRegistryLabel" },                     
            { "Ref": "StelligentDemoDockerImage" }                              
          ]]},
```

The image name can now be specified via the CFN ECS template:

```
[ec2-user@ip-10-200-0-32 ~]$ docker images
REPOSITORY                                TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
stelligent/stelligent-demo-docker-image   latest              05b545320fdb        3 days ago          642.9 MB
amazon/amazon-ecs-agent                   latest              edda11aee701        3 weeks ago         8.256 MB
```

Another method is to create an S3 backed repostory on the EC2 container instance.  Since the S3 bucket is already configured with a registry containing an image.  An S3 registry has been created in:

'''
s3://stelligent-demo-docker-repo/registry
'''

The registry gets created on the local machine and the resgistry service runs from a container there.  It's simply configured to use S3 to store it's registry data versus the local filesystem.  An S3 backed registry can be created with the following command:

'''
docker run -e SETTINGS_FLAVOR=s3 -e AWS_BUCKET=stelligent-demo-docker-repo -e STORAGE_PATH=/registry -e AWS_KEY=<access_key> -e AWS_SECRET=<secret_key> -e SEACH_BACKEND=sqlalchemy -p 5000:5000 --name registry -d registry
'''

That will start up a registry container named 'registry' that listens on localhost port 5000.  The image needs to be created and added.  This can be done by creating the image, pushing it into the registry and optionally, tagging it:

'''
export IMAGE=$(docker build . | tail -1 | awk '{print $NF}')
docker push localhost:5000/${IMAGE}
docker tag ${IMAGE} localhost:5000/stelligent-demo-docker-image:latest
'''

To add this method to the CFN the UserData lines above need to be replaced with the docker registry creation line above.  This method will take a few moments longer as it will need to pull down the Docker registery container before it can access the stelligent-demo-docker-image.

The reason I did not continue with this method is because Docker requires the AWS access and secret keys on the command line to access the S3 bucket, regardless of the IAM Role associated with the EC2 instance.  At this time I believe this is not the best solution given the alternative.

## Jenkins

## Relational Database Service (RDS)

## Simple Storage Service (S3)

## Security Groups

## Virtual Private Cloud
