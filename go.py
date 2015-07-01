#!/usr/bin/env python

import argparse
import hashlib
import json
import os
import re
import socket
import sys
import time
import zipfile
from datetime import datetime
from pprint import pprint
from time import sleep

from boto.cloudformation import connect_to_region as cfn_connect
from boto.codedeploy import connect_to_region as codedeploy_connect
from boto.ec2 import connect_to_region as ec2_connect
from boto.exception import BotoServerError, EC2ResponseError, S3ResponseError
from boto.iam import connect_to_region as iam_connect
from boto.s3 import connect_to_region as s3_connect
from boto.s3.key import Key as S3Key

#  OPTIONAL: Provide prebaked AMIs with python2.7, jenkins, and puppet.
#  See configSets "cfg-packages" and "cfg-sys-commands" for reference.
CUSTOM_AMI_MAP = {
    'us-east-1': 'ami-f798779c',
    'us-west-2': 'ami-bf9ea08f'
}
STACK_DATA = {
    'main': {'key_prefix': 'stelligent-demo',
             'prefix': 'stelligent-demo',
             'template': 'cloudformation.json',
             'type': 'MAIN'},
    's3': {'prefix': 'stelligent-demo-s3',
           'template': 'cloudformation/cloudformation.s3.json',
           'type': 'S3'},
    'vpc': {'prefix': 'stelligent-demo-vpc',
            'template': 'cloudformation/cloudformation.vpc.json',
            'type': 'VPC'},
    'sg': {'prefix': 'stelligent-demo-sg',
           'template': 'cloudformation/cloudformation.sg.json',
           'type': 'SG'},
    'rds': {'db_prefix': 'stelligent',
            'prefix': 'stelligent-demo-rds',
            'template': 'cloudformation/cloudformation.rds.json',
            'type': 'RDS'},
    'eb': {'prefix': 'stelligent-demo-eb',
            'template': 'cloudformation/cloudformation.eb.json',
            'type': 'EB'},
    'ecs': {'prefix': 'stelligent-demo-ecs',
            'template': 'cloudformation/cloudformation.ecs.json',
            'type': 'ECS'}
}
DEFAULT_REGION = 'us-east-1'
ROUTE53_DOMAIN = 'elasticoperations.com'
MAIN_S3_BUCKET = 'stelligent-demo'  # Permanent S3 Bucket
MAIN_S3_BUCKET_REGION = 'us-east-1'
DOCKER_ZIPFILE = 'stelligent-demo.zip'
DOCKER_FILES = ['Dockerfile', 'application.py', 'requirements.txt']
FILES_TO_S3 = ['jenkins/seed.xml.erb',
               'puppet/installJenkins.pp',
               'puppet/installJenkinsJob.pp',
               'puppet/installJenkinsPlugins.pp',
               'puppet/installJenkinsUsers.pp',
               'puppet/installJenkinsSecurity.pp',
               DOCKER_ZIPFILE]
INGRESS_PORTS = ['22', '2222', '8080']
ALLOWED_ACTIONS = ["build", "destroy", "info", "test"]

#  FIXME: These are hard-coded elsewhere, make dynamic everywhere.
CODEDEPLOY_APP_NAME = 'stelligent-demo'
CODEDEPLOY_GROUP_NAME = 'stelligent-demo'


#  Note: IAM_ROLE_NAME and IAM_POLICY_NAME will have the region and hash
#        appended as 'StelligentDemoRole-us-east-1' to allow multi-region support
IAM_ROLE_NAME = 'StelligentDemoCodeDeployRole'
IAM_ROLE_DOC = 'codedeploy/StelligentDemoCodeDeployRole.json'
IAM_POLICY_NAME = 'StelligentDemoCodeDeployPolicy'
IAM_POLICY_DOC = 'codedeploy/StelligentDemoCodeDeployPolicy.json'

#  Resource Logical IDs
JENKINS_INSTANCE = "StelligentDemoJenkins"
WEB_ASG_NAME = 'StelligentDemoWebASG'
DEMO_RDS = 'StelligentDemoMysql'
DEMO_ELB = 'StelligentDemoELB'
DEMO_ECS = 'StelligentDemoECS'
DEMO_S3_BUCKET = 'StelligentDemoBucket'  # Ephemeral Bucket
DEMO_DOCKER_ENV = 'StelligentDemoDockerEnvironment'


def ip_address_type(location):
    try:
        socket.inet_aton(location)
    except:
        raise argparse.ArgumentTypeError("%s is not a valid IP Address" %
                                         location)
    else:
        return location


def list_and_get_stacks(cfn_connection, allow_all=False):
    stack_list = []
    all_stacks = cfn_connection.describe_stacks()
    for type in STACK_DATA:
        match_stacks = [[stack, STACK_DATA[type]['type']] for
                        stack in all_stacks if
                        re.match('%s-(\d+)' % STACK_DATA[type]['prefix'],
                                 stack.stack_name)]
        stack_list = stack_list + match_stacks
    if stack_list:
        response = 0
        custom_range = range(1, len(stack_list)+1)
        while response not in custom_range:
            for index, stack in enumerate(stack_list):
                print "%s) %s (%s) - %s" % (index + 1, stack[0].stack_name,
                                            stack[1], stack[0].stack_status)
            if allow_all:
                print "nc) Non-Core: Select all but VPC/SG/RDS."
                print "all) Select all."
            print "q) Quit."
            response = raw_input("Which stack?  ")
            if response in ['q', 'quit', 'exit']:
                sys.exit(0)
            if response == 'nc' and allow_all:
                return [stack for stack in stack_list if stack[1] not in [
                    'VPC', 'SG', 'RDS']]
            if response == 'all' and allow_all:
                return stack_list
            try:
                response = int(response)
            except ValueError:
                pass
        return [stack_list[response - 1]]
    else:
        print "No stacks found. Exiting."
        sys.exit(0)


def prepare_docker_zip():
    sys.stdout.write("Repacking %s..." % DOCKER_ZIPFILE)
    sys.stdout.flush()
    try:
        os.remove(DOCKER_ZIPFILE)
    except OSError:
        pass
    with zipfile.ZipFile(DOCKER_ZIPFILE, mode='w') as zf:
        os.chdir('docker')
        for f in DOCKER_FILES:
            zf.write(f)
        os.chdir('..')
    print "Done!"


def copy_files_to_s3(s3_connection, bucket):
    prepare_docker_zip()
    sys.stdout.write("Sending files to S3...")
    sys.stdout.flush()
    s3_bucket = s3_connection.get_bucket(bucket)
    s3_key = S3Key(s3_bucket)
    for f in FILES_TO_S3:
        s3_key.key = os.path.basename(f)
        with open(f) as f:
            s3_key.set_contents_from_file(f)
    print "Done!"


def create_and_upload_index_to_s3(s3, outputs=dict()):
    output_key = "StelligentDemoBucketURL"
    bucket_url = ([output.value for output in outputs
                  if output.key == output_key])[0]
    bucket_name = re.sub(r'http://(.*).s3-website.*', r'\1', bucket_url)
    contents = """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
        <title>Demo Index File in S3 Bucket</title>
    </head>

    <body>
    <h1>Stelligent Demo Stack</h1>
    <pre>"""
    for output in outputs:
        contents += "%40s : %s\n" % (output.key, output.value)
    s3_bucket = s3.get_bucket(bucket_name)
    s3_key = S3Key(s3_bucket)
    s3_key.key = "index.html"
    s3_key.set_metadata('Content-Type', 'text/html')
    s3_key.set_contents_from_string(contents)
    s3_key.set_acl('public-read')


def delete_stack_name_from_s3(s3_connection, bucket, target):
    s3_bucket = s3_connection.get_bucket(bucket)
    s3_key = target
    s3_bucket.delete_key(s3_key)
    print "Deleted stack name from s3 %s." % target


def inject_custom_ami(resource, data, parameters, ec2_connection, region):
    try:
        ami = CUSTOM_AMI_MAP[region]
        ec2_connection.get_image(ami)
    except KeyError:
        print "No Custom AMI defined for %s. See CUSTOM_AMI_MAP." % region
        print "Using default AMI for %s." % resource
        return data, parameters
    except EC2ResponseError:
        print "AMI %s does not exist in %s. See CUSTOM_AMI_MAP." % (ami,
                                                                    region)
        print "Using default AMI for %s." % resource
        return data, parameters
    data['Resources'][resource]['Properties']['ImageId'] = ami
    resource_config_set = "%sConfigSet" % resource
    parameters.append((resource_config_set, "quick"))
    print "Using image %s for %s." % (ami, resource)
    return data, parameters


def add_cidr_subnet(locations):
    locations_with_cidr = list()
    for location in locations:
        if location == '0.0.0.0':
            location = '%s/0' % location
        else:
            location = '%s/32' % location
        locations_with_cidr.append(location)
    return locations_with_cidr


def inject_locations(locations, data):
    sys.stdout.write("Setting security source(s) to %s..." % locations)
    sys.stdout.flush()
    for location in locations:
        for port in INGRESS_PORTS:
            item = {'IpProtocol': 'tcp',
                    'FromPort': port,
                    'ToPort': port,
                    'CidrIp': '%s' % location}
            data['Resources']['StelligentDemoPublicLockedSecurityGroup']['Properties']['SecurityGroupIngress'].append(item)
    print "Done!"
    return data


def create_cfn_stack(cfn_connection, stack_name, data, build_params=None,
                     capabilities=['CAPABILITY_IAM'], disable_rollback='true'):
    build_params = build_params or list()
    cfn_connection.create_stack(
        stack_name,
        template_body=json.dumps(data, indent=2),
        parameters=build_params,
        capabilities=capabilities,
        disable_rollback=disable_rollback
    )


def get_stack_outputs(cfn_connection, stack_name):
    outputs = ''
    while not outputs:
        stack = cfn_connection.describe_stacks(stack_name)[0]
        outputs = stack.outputs
        if not outputs:
            time.sleep(2)
    return outputs


def get_or_create_stack(cfn_connection, all_stacks, stack_data, timestamp,
                        build_params=None, check_outputs=None, create=False,
                        wait=True, locations=None):
    stack = None
    created = False
    if create:
        stacks = None
    else:
        stacks = [stack_match for stack_match in all_stacks if
                  re.match('%s-(\d+)' % stack_data['prefix'],
                           stack_match.stack_name) and
                  stack_match.stack_status == 'CREATE_COMPLETE']
    if stacks:
        if check_outputs:
            for check_stack in stacks:
                subset = [x.value for x in check_outputs]
                fullset = [x.value for x in check_stack.parameters]
                if set(subset).issubset(fullset):
                    stack = check_stack
                    break
        else:
            # Default to first, complete stack
            stack = stacks[0]
    if stack:
        print "Using %s %s..." % (stack_data['type'], stack.stack_name)
        return stack.stack_name, stack.outputs, created
    else:
        created = True
        stack_name = '%s-%s' % (stack_data['prefix'], timestamp)
        with open(stack_data['template']) as data_file:
            data = json.load(data_file)
        if stack_data['type'] == 'S3':
            for location in locations:
                data['Resources']['StelligentDemoBucketPolicy']['Properties']['PolicyDocument']['Statement'][0]['Condition']['IpAddress']['aws:SourceIp'].append(location)
        print "Creating %s stack %s..." % (stack_data['type'],
                                           stack_name)
        create_cfn_stack(cfn_connection, stack_name, data,
                         build_params=build_params)
        if wait:
            get_resource_id(cfn_connection, stack_name)
            outputs = get_stack_outputs(cfn_connection, stack_name)
        else:
            outputs = None
        return stack_name, outputs, created


def create_ec2_key_pair(ec2_connection, key_pair_name):
    sys.stdout.write("Creating EC2 Key Pair %s..." % key_pair_name)
    sys.stdout.flush()
    kp = ec2_connection.create_key_pair(key_pair_name)
    print "Done!"
    sys.stdout.write("Creating private key %s.pem locally..." % key_pair_name)
    sys.stdout.flush()
    kp.save('.')
    print "Done!"
    return kp.material


def delete_ec2_key_pair(ec2_connection, key_pair_name):
    sys.stdout.write("Deleting EC2 Key Pair %s..." % key_pair_name)
    sys.stdout.flush()
    ec2_connection.delete_key_pair(key_pair_name)
    print "Done!"
    key_file = '%s.pem' % key_pair_name
    if os.path.isfile(key_file):
        os.remove(key_file)
        print "Deleted Private Key %s." % key_file


def create_iam_role(iam_connection, role_name, role_doc):
    sys.stdout.write("Creating IAM Role %s..." % role_name)
    sys.stdout.flush()
    with open(role_doc) as doc:
        result = iam_connection.create_role(
            role_name, assume_role_policy_document=doc.read())
    print "Done!"
    return result['create_role_response']['create_role_result']['role']['arn']


def delete_iam_role(iam_connection, role_name):
    sys.stdout.write("Deleting IAM Role %s..." % role_name)
    sys.stdout.flush()
    try:
        iam_connection.delete_role(role_name)
    except BotoServerError:
        pass
    print "Done!"


def put_iam_role_policy(iam_connection, role_name, policy_name,
                        policy_doc):
    sys.stdout.write("Adding policy %s..." % policy_name)
    sys.stdout.flush()
    with open(policy_doc) as doc:
        iam_connection.put_role_policy(role_name, policy_name, doc.read())
    print "Done!"


def delete_iam_policy(iam_connection, role_name, policy_name):
    sys.stdout.write("Deleting policy %s..." % policy_name)
    sys.stdout.flush()
    try:
        iam_connection.delete_role_policy(role_name, policy_name)
    except BotoServerError:
        pass
    print "Done!"


def create_codedeploy_application(codedeploy_connection, app_name):
    sys.stdout.write("Creating CodeDeploy Application %s..." % app_name)
    sys.stdout.flush()
    codedeploy_connection.create_application(app_name)
    print "Done!"


def delete_codedeploy_application(codedeploy_connection, app_name):
    sys.stdout.write("Deleting CodeDeploy Application %s..." % app_name)
    sys.stdout.flush()
    codedeploy_connection.delete_application(app_name)
    print "Done!"


def create_codedeploy_deployment_group(codedeploy_connection, app_name,
                                       group_name, asg_id, service_role):
    sys.stdout.write("Creating CodeDeploy Deployment Group %s..." % group_name)
    sys.stdout.flush()
    codedeploy_connection.create_deployment_group(
        app_name,
        group_name,
        auto_scaling_groups=[asg_id],
        service_role_arn=service_role
    )
    print "Done!"
    pass


def delete_codedeploy_deployment_group(codedeploy_connection, app_name,
                                       group_name):
    sys.stdout.write("Deleting CodeDeploy Deployment Group %s..." % group_name)
    sys.stdout.flush()
    codedeploy_connection.delete_deployment_group(app_name, group_name)
    print "Done!"


def empty_related_buckets(s3_connection, bucket_name):
    #  Safeguard. Do not delete items from main bucket.
    if bucket_name == MAIN_S3_BUCKET:
        return
    try:
        bucket = s3_connection.get_bucket(bucket_name)
        keys = bucket.get_all_keys()
        if keys:
            print "Deleting the following files from %s:" % bucket_name
            print keys
            bucket.delete_keys(keys)
    except S3ResponseError:
        pass


def get_resource_id(cfn_connection, stack_name, resource_name=None):
    #  Initial Check
    if resource_name:
        resource_label = resource_name
    else:
        resource_label = stack_name
    try:
        #  FIXME: Must be a better way...
        if resource_name:
            resource = cfn_connection.describe_stack_resource(stack_name,
                                                              resource_name)
            info = resource['DescribeStackResourceResponse']['DescribeStackResourceResult']['StackResourceDetail']
            status = info['ResourceStatus']
            resource_id = info['PhysicalResourceId']
        else:
            status = cfn_connection.describe_stacks(stack_name)[0].stack_status
            resource_id = cfn_connection.describe_stacks(
                stack_name)[0].stack_id
    except BotoServerError:
        status = "NOT STARTED"
    while status != "CREATE_COMPLETE":
        sys.stdout.write("\rWaiting for %s        " % resource_label)
        sys.stdout.flush()
        sleep(1)
        sys.stdout.write("\rWaiting for %s.       " % resource_label)
        sys.stdout.flush()
        sleep(1)
        sys.stdout.write("\rWaiting for %s..      " % resource_label)
        sys.stdout.flush()
        sleep(1)
        sys.stdout.write("\rWaiting for %s...     " % resource_label)
        sys.stdout.flush()
        try:
            #  FIXME: Must be a better way...
            if resource_name:
                resource = cfn_connection.describe_stack_resource(
                    stack_name, resource_name)
                info = resource['DescribeStackResourceResponse']['DescribeStackResourceResult']['StackResourceDetail']
                status = info['ResourceStatus']
                resource_id = info['PhysicalResourceId']
            else:
                status = cfn_connection.describe_stacks(
                    stack_name)[0].stack_status
        except BotoServerError:
            status = "NOT STARTED"
        if status.endswith('FAILED'):
            sys.stdout.write("\n")
            print "Stack Failed. Exiting..."
            sys.exit(1)
        if status.endswith('COMPLETE'):
            sys.stdout.write("\rWaiting for %s...Done!" % resource_label)
            sys.stdout.flush()
            sys.stdout.write("\n")
    return resource_id


def set_stack_name_in_s3(s3_connection, stack_name, dest_name, bucket):
    s3_bucket = s3_connection.get_bucket(bucket)
    s3_key = S3Key(s3_bucket)
    s3_key.key = dest_name
    s3_key.set_contents_from_string(stack_name)


def outputs_to_parameters(outputs, params=None):
    params = params or list()
    for output in outputs:
        params.append((output.key, output.value))
    return params


def build(connections, region, locations, hash_id, full, warm):
    locations = add_cidr_subnet(locations)
    timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
    all_stacks = connections['cfn'].describe_stacks()
    if warm:
        print "Only launching VPC, SG, and RDS in %s..." % region
    else:
        #  Setup EC2 Key Pair
        key_pair_name = "%s-%s" % (STACK_DATA['main']['key_prefix'], timestamp)
        private_key = create_ec2_key_pair(connections['ec2'], key_pair_name)
        #  Copy files to S3
        copy_files_to_s3(connections['main_s3'], MAIN_S3_BUCKET)
        #  Launch ElasticBeanstalk Stack, don't wait
        eb_params = list()
        eb_params.append(("HashID", hash_id))
        eb_params.append(("DemoRegion", region))
        eb_params.append(("StelligentDemoZoneName", ROUTE53_DOMAIN))
        eb_params.append(("KeyName", key_pair_name))
        eb_stack, eb_outputs, eb_created = get_or_create_stack(
            connections['cfn'], all_stacks, STACK_DATA['eb'], timestamp,
            build_params=eb_params, create=True, wait=False
        )
        #  Launch S3 Stack, don't wait
        s3_params = list()
        s3_params.append(("DemoRegion", region))
        s3_params.append(("StelligentDemoZoneName", ROUTE53_DOMAIN))
        s3_stack, s3_outputs, s3_created = get_or_create_stack(
            connections['cfn'], all_stacks, STACK_DATA['s3'], timestamp,
            build_params=s3_params, create=True, wait=False,
            locations=locations
        )
    #  Cascading Outputs/Parameters
    #  Get or create VPC
    vpc_stack, vpc_outputs, vpc_created = get_or_create_stack(
        connections['cfn'], all_stacks, STACK_DATA['vpc'], timestamp,
        create=full
    )
    #  Get or create SG
    sg_params = outputs_to_parameters(vpc_outputs)
    sg_stack, sg_outputs, sg_created = get_or_create_stack(
        connections['cfn'], all_stacks, STACK_DATA['sg'], timestamp,
        build_params=sg_params, check_outputs=vpc_outputs, create=vpc_created
    )
    if not warm:
        #  Launch ECS Stack, don't wait
        ecs_params = outputs_to_parameters(sg_outputs)
        ecs_params.append(("KeyName", key_pair_name))
        ecs_params.append(('StelligentDemoECSClusterName', DEMO_ECS))
        ecs_stack, ecs_outputs, ecs_created = get_or_create_stack(
            connections['cfn'], all_stacks, STACK_DATA['ecs'], timestamp,
            build_params=ecs_params, check_outputs=sg_outputs, create=True,
            wait=False
        )
    #  Get or create RDS
    rds_params = outputs_to_parameters(sg_outputs)
    rds_stack, rds_outputs, rds_created = get_or_create_stack(
        connections['cfn'], all_stacks, STACK_DATA['rds'], timestamp,
        build_params=rds_params, check_outputs=sg_outputs, create=sg_created
    )
    if warm:
        print "Warming complete. VPC, SG, and RDS found or created."
        sys.exit(0)
    #  Wait for S3
    get_resource_id(connections['cfn'], s3_stack)
    s3_outputs = get_stack_outputs(connections['cfn'], s3_stack)
    #  Setup Main Stack
    stack_name = "%s-%s" % (STACK_DATA['main']['prefix'], timestamp)
    build_params = outputs_to_parameters(s3_outputs)
    build_params += outputs_to_parameters(rds_outputs)
    build_params.append(("PrimaryPermanentS3Bucket", MAIN_S3_BUCKET))
    build_params.append(("StelligentDemoName", stack_name))
    build_params.append(("DemoRegion", region))
    build_params.append(("StelligentDemoZoneName", ROUTE53_DOMAIN))
    build_params.append(("HashID", hash_id))
    build_params.append(("KeyName", key_pair_name))
    build_params.append(("PrivateKey", private_key))
    with open(STACK_DATA['main']['template']) as data_file:
        data = json.load(data_file)
    #  Inject locations
    data = inject_locations(locations, data)
    #  Inject Custom AMI
    data, build_params = inject_custom_ami(
        JENKINS_INSTANCE, data, build_params, connections['ec2'], region)
    #  Setup IAM Roles/Policies
    IRN = "-".join((IAM_ROLE_NAME, region, hash_id))
    IPN = "-".join((IAM_POLICY_NAME, region, hash_id))
    role_arn = create_iam_role(connections['iam'], IRN, IAM_ROLE_DOC)
    put_iam_role_policy(connections['iam'], IRN, IPN, IAM_POLICY_DOC)
    #  Add Extra Information to Stack
    CAN = "-".join((CODEDEPLOY_APP_NAME, region, hash_id))
    CGN = "-".join((CODEDEPLOY_GROUP_NAME, region, hash_id))
    build_params.append(("CodeDeployAppName", CAN))
    build_params.append(("CodeDeployDeploymentGroup", CGN))
    #  Inject Database name
    db_name = "%s%s" % (STACK_DATA['rds']['db_prefix'], timestamp)
    build_params.append(("StelligentDemoDBName", db_name))
    #  Create Stack
    sys.stdout.write("Launching CloudFormation Stack in %s..." % region)
    sys.stdout.flush()
    create_cfn_stack(connections['cfn'], stack_name, data, build_params)
    #  Upload stack name to S3
    dest_name = "cloudformation.stack.name-%s-%s" % (region, hash_id)
    set_stack_name_in_s3(connections['main_s3'], stack_name,
                         dest_name, MAIN_S3_BUCKET)
    print "Done!"
    #  Give Feedback whilst we wait...
    get_resource_id(connections['cfn'], stack_name, DEMO_ELB)
    asg_id = get_resource_id(connections['cfn'], stack_name, WEB_ASG_NAME)
    #  Setup CodeDeploy
    create_codedeploy_application(connections['codedeploy'],
                                  CAN)
    create_codedeploy_deployment_group(connections['codedeploy'],
                                       CAN, CGN, asg_id, role_arn)
    get_resource_id(connections['cfn'], stack_name, JENKINS_INSTANCE)
    # Wait for Elastic Beanstalk
    get_resource_id(connections['cfn'], eb_stack)
    print "Gathering Stack Outputs...almost there!"
    main_outputs = get_stack_outputs(connections['cfn'], stack_name)
    eb_outputs = get_stack_outputs(connections['cfn'], eb_stack)
    ecs_outputs = get_stack_outputs(connections['cfn'], ecs_stack)
    outputs = main_outputs + eb_outputs + ecs_outputs
    outputs = sorted(outputs, key=lambda k: k.key)
    # Upload index.html to transient demo bucket
    create_and_upload_index_to_s3(connections['s3'], outputs)
    print "Outputs:"
    for output in outputs:
        print '%s = %s' % (output.key, output.value)


def destroy(connections, region):
    stacks = list_and_get_stacks(connections['cfn'], allow_all=True)
    for stack in stacks:
        stack, stack_type = stack
        if stack.stack_status == "DELETE_IN_PROGRESS":
            print "Stack %s deletion already in progress." % stack.stack_name
            continue
        if stack_type == 'S3':
            outputs = {x.key: x.value for x in stack.outputs}
            try:
                s3_bucket = outputs['StelligentDemoBucket']
                empty_related_buckets(connections['s3'], s3_bucket)
            except KeyError:
                pass
        elif stack_type == 'MAIN':
            parameters = {x.key: x.value for x in stack.parameters}
            hash_id = parameters['HashID']
            #  Destroy CodeDeploy
            delete_codedeploy_deployment_group(
                connections['codedeploy'],
                parameters['CodeDeployAppName'],
                parameters['CodeDeployDeploymentGroup'])
            delete_codedeploy_application(connections['codedeploy'],
                                          parameters['CodeDeployAppName'])
            #  Destroy IAM Roles/Policies
            IRN = "-".join((IAM_ROLE_NAME, region, hash_id))
            IPN = "-".join((IAM_POLICY_NAME, region, hash_id))
            delete_iam_policy(connections['iam'], IRN, IPN)
            delete_iam_role(connections['iam'], IRN)
            #  Destroy EC2 Key Pair
            delete_ec2_key_pair(connections['ec2'], parameters['KeyName'])
            #  Remove the stackname from S3
            dest_name = "cloudformation.stack.name-%s-%s" % (region, hash_id)
            delete_stack_name_from_s3(connections['main_s3'], MAIN_S3_BUCKET,
                                      dest_name)
        #  Destroy Stack
        sys.stdout.write("Deleting the CloudFormation Stack %s..." %
                         stack.stack_name)
        print "Deleting!"
        connections['cfn'].delete_stack(stack.stack_name)


def info(connections):
    stack = list_and_get_stacks(connections['cfn'])[0]
    stack, _ = stack
    pprint(stack.parameters, indent=2)
    pprint(stack.outputs, indent=2)


def main():
    new_hash = hashlib.md5(str(time.time())).hexdigest()[:8]
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=ALLOWED_ACTIONS, action="store",
                        help="Action to take against the stack(s)")
    parser.add_argument("-l", "--location", nargs='*', action="store",
                        dest="locations", help="""If building, provide the
                        IP Address(es) from which ssh is allowed.\n
                        Example: './go.py build -l xx.xx.xx.xx yy.yy.yy.yy""",
                        type=ip_address_type, default=["0.0.0.0"])
    parser.add_argument('--region', action="store", dest="region",
                        default=DEFAULT_REGION)
    parser.add_argument('--hash', action="store", dest="hash_id",
                        help="""Define the hash to use for multiple
                        deployments.  If left blank, the hash will be
                        generated.""", default=new_hash)
    parser.add_argument('--full', action='store_true',
                        help="Always build all components. (VPC, RDS, etc.)")
    parser.add_argument('--warm', action='store_true',
                        help="Only build VPC, SG, and RDS")
    args = parser.parse_args()
    connections = dict()
    connections['cfn'] = cfn_connect(args.region)
    if args.action == "info":
        info(connections)
        sys.exit(0)
    connections['codedeploy'] = codedeploy_connect(args.region)
    connections['ec2'] = ec2_connect(args.region)
    connections['iam'] = iam_connect(args.region)
    connections['main_s3'] = s3_connect(MAIN_S3_BUCKET_REGION)
    connections['s3'] = s3_connect(args.region)
    if args.action == "test":
        #  Test pieces here
        sys.exit(0)
    if args.action == "build":
        if not args.locations:
            print "Please provide at least one IP Address."
            parser.print_help()
            sys.exit(1)
        build(connections, args.region, args.locations, args.hash_id,
              args.full, args.warm)
    elif args.action == "destroy":
        destroy(connections, args.region)


if __name__ == '__main__':
    main()
