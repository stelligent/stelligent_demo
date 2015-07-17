#!/usr/bin/env python

import argparse
import getpass
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
DOCKER_ZIPFILE = 'stelligent-demo.zip'
DOCKER_FILES = ['Dockerfile', 'index.html', 'stelogo.png']
FILES_TO_S3 = ['cloudformation/cloudformation.asg.json',
               'cloudformation/cloudformation.jenkins.json',
               'jenkins/seed.xml.erb',
               'puppet/installJenkins.pp',
               'puppet/installJenkinsJob.pp',
               'puppet/installJenkinsPlugins.pp',
               'puppet/installJenkinsSecurity.pp',
               DOCKER_ZIPFILE]
JENKINS_USER = 'stelligent_demo'
JENKINS_EMAIL = 'stelligent@example.com'
JENKINS_PASSWORD = 'changeme123'
INGRESS_PORTS = ['22', '2222', '8080']
ALLOWED_ACTIONS = ["build", "destroy", "info", "test"]

#  FIXME: These are hard-coded elsewhere, make dynamic everywhere.
CODEDEPLOY_APP_NAME = 'stelligent-demo'
CODEDEPLOY_GROUP_NAME = 'stelligent-demo'


#  Note: IAM_ROLE_NAME and IAM_POLICY_NAME will have the region and hash
#        appended as 'StelligentDemoRole-us-east-1' for multi-region support
IAM_ROLE_NAME = 'StelligentDemoCodeDeployRole'
IAM_ROLE_DOC = 'codedeploy/StelligentDemoCodeDeployRole.json'
IAM_POLICY_NAME = 'StelligentDemoCodeDeployPolicy'
IAM_POLICY_DOC = 'codedeploy/StelligentDemoCodeDeployPolicy.json'

#  Resource Logical IDs
JENKINS_STACK = "StelligentDemoJenkinsStack"
ASG_STACK = "StelligentDemoASGStack"
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
                        re.match('%s-(\d+)$' % STACK_DATA[type]['prefix'],
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
                print "warm) Warm State: Select all but VPC/SG/RDS."
                print "all) Select all."
            print "q) Quit."
            response = raw_input("Which stack?  ")
            if response in ['q', 'quit', 'exit']:
                sys.exit(0)
            if response == 'warm' and allow_all:
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


def copy_files_to_s3(s3_connection, bucket, files):
    prepare_docker_zip()
    sys.stdout.write("Sending files to S3...")
    sys.stdout.flush()
    s3_bucket = s3_connection.get_bucket(bucket)
    s3_key = S3Key(s3_bucket)
    for f in files:
        s3_key.key = os.path.basename(f)
        with open(f) as opened_file:
            s3_key.set_contents_from_file(opened_file)
    print "Done!"


def create_and_upload_index_to_s3(s3, outputs=None):
    outputs = outputs or dict()
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
    parameters.append(("JenkinsAMI", ami))
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
    try:
        bucket = s3_connection.get_bucket(bucket_name)
        keys = bucket.get_all_keys()
        if keys:
            print "Deleting the following files from %s:" % bucket_name
            for key in keys:
                print key.name
            bucket.delete_keys(keys)
    except S3ResponseError:
        pass


def get_resource_id(cfn_connection, stack_name, resource_name=None, wait=True):
    #  Initial Check
    if resource_name:
        resource_label = resource_name
    else:
        resource_label = stack_name
    status = "NOT_STARTED"
    waited = False
    while status != "CREATE_COMPLETE":
        try:
            #  FIXME: Must be a better way...
            if resource_name:
                resource = cfn_connection.describe_stack_resources(
                    stack_name, resource_name)[0]
                status = resource.resource_status
                resource_id = resource.physical_resource_id
                if not wait and resource_id:
                    if waited:
                        sys.stdout.write("\rWaiting for %s...Started!" %
                                         resource_label)
                        sys.stdout.flush()
                        sys.stdout.write("\n")
                    return resource_id
            else:
                status = cfn_connection.describe_stacks(
                    stack_name)[0].stack_status
                resource_id = cfn_connection.describe_stacks(
                    stack_name)[0].stack_id
        except IndexError:
            pass
        waited = True
        sys.stdout.write("\rWaiting for %s.       " % resource_label)
        sys.stdout.flush()
        sleep(1)
        sys.stdout.write("\rWaiting for %s..      " % resource_label)
        sys.stdout.flush()
        sleep(1)
        sys.stdout.write("\rWaiting for %s...     " % resource_label)
        sys.stdout.flush()
        sleep(1)
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


def fetch_parameters(outputs, params=list()):
    results = list()
    for param in params:
        value = ([output.value for output in outputs
                 if output.key == param])[0]
        if value is not None:
            results.append((param, value))

    return results


def build(connections, args):
    locations = add_cidr_subnet(args.locations)
    timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
    all_stacks = connections['cfn'].describe_stacks()
    if args.warm:
        print "Only launching VPC, SG, and RDS in %s..." % args.region
    else:
        #  Setup EC2 Key Pair
        key_pair_name = "%s-%s" % (STACK_DATA['main']['key_prefix'], timestamp)
        private_key = create_ec2_key_pair(connections['ec2'], key_pair_name)
        ''' # FIXME: Change EB to something other than docker then re-enable
        #  Launch ElasticBeanstalk Stack, don't wait
        eb_params = list()
        eb_params.append(("HashID", args.hash_id))
        eb_params.append(("DemoRegion", args.region))
        eb_params.append(("StelligentDemoZoneName", ROUTE53_DOMAIN))
        eb_params.append(("KeyName", key_pair_name))
        eb_stack, eb_outputs, eb_created = get_or_create_stack(
            connections['cfn'], all_stacks, STACK_DATA['eb'], timestamp,
            build_params=eb_params, create=True, wait=False
        )
        '''
        #  Launch S3 Stack, don't wait
        s3_params = list()
        s3_params.append(("DemoRegion", args.region))
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
        create=args.full
    )
    #  Get or create SG
    sg_params = outputs_to_parameters(vpc_outputs)
    sg_stack, sg_outputs, sg_created = get_or_create_stack(
        connections['cfn'], all_stacks, STACK_DATA['sg'], timestamp,
        build_params=sg_params, check_outputs=vpc_outputs, create=vpc_created
    )
    #  Get or create RDS
    rds_params = outputs_to_parameters(sg_outputs)
    rds_stack, rds_outputs, rds_created = get_or_create_stack(
        connections['cfn'], all_stacks, STACK_DATA['rds'], timestamp,
        build_params=rds_params, check_outputs=sg_outputs, create=sg_created
    )
    if args.warm:
        print "Warming complete. VPC, SG, and RDS found or created."
        sys.exit(0)
    #  Wait for S3
    get_resource_id(connections['cfn'], s3_stack)
    s3_outputs = get_stack_outputs(connections['cfn'], s3_stack)
    s3_outputs_parsed = {x.key: x.value for x in s3_outputs}
    ephemeral_bucket = s3_outputs_parsed[DEMO_S3_BUCKET]
    copy_files_to_s3(connections['s3'], ephemeral_bucket, FILES_TO_S3)
    #  Launch ECS Stack, don't wait
    ecs_params = fetch_parameters(sg_outputs,
        ['StelligentDemoPublicSecurityGroup'])
    ecs_params.extend(fetch_parameters(vpc_outputs, 
        ['StelligentDemoPublicSubnet',
         'StelligentDemoVPC']))
    ecs_params.extend(fetch_parameters(s3_outputs, [DEMO_S3_BUCKET]))
    ecs_params.append(("KeyName", key_pair_name))
    ecs_params.append(('StelligentDemoECSClusterName', DEMO_ECS))
    ecs_stack, ecs_outputs, ecs_created = get_or_create_stack(
        connections['cfn'], all_stacks, STACK_DATA['ecs'], timestamp,
        build_params=ecs_params, check_outputs=sg_outputs, create=True,
        wait=False
    )
    #  Setup Main Stack
    stack_name = "%s-%s" % (STACK_DATA['main']['prefix'], timestamp)
    build_params = outputs_to_parameters(s3_outputs)
    build_params += outputs_to_parameters(rds_outputs)
    build_params.append(("StelligentDemoName", stack_name))
    build_params.append(("DemoRegion", args.region))
    build_params.append(("StelligentDemoZoneName", ROUTE53_DOMAIN))
    build_params.append(("HashID", args.hash_id))
    build_params.append(("KeyName", key_pair_name))
    build_params.append(("PrivateKey", private_key))
    build_params.append(("JenkinsUser", args.jenkins_user))
    build_params.append(("JenkinsEmail", args.jenkins_email))
    build_params.append(("JenkinsPassword", args.jenkins_password))
    with open(STACK_DATA['main']['template']) as data_file:
        data = json.load(data_file)
    #  Inject locations
    data = inject_locations(locations, data)
    #  Inject Custom AMI
    data, build_params = inject_custom_ami(
        JENKINS_INSTANCE, data, build_params, connections['ec2'], args.region)
    #  Setup IAM Roles/Policies
    IRN = "-".join((IAM_ROLE_NAME, args.region, args.hash_id))
    IPN = "-".join((IAM_POLICY_NAME, args.region, args.hash_id))
    role_arn = create_iam_role(connections['iam'], IRN, IAM_ROLE_DOC)
    put_iam_role_policy(connections['iam'], IRN, IPN, IAM_POLICY_DOC)
    #  Add Extra Information to Stack
    CAN = "-".join((CODEDEPLOY_APP_NAME, args.region, args.hash_id))
    CGN = "-".join((CODEDEPLOY_GROUP_NAME, args.region, args.hash_id))
    build_params.append(("CodeDeployAppName", CAN))
    build_params.append(("CodeDeployDeploymentGroup", CGN))
    #  Inject Database name
    db_name = "%s%s" % (STACK_DATA['rds']['db_prefix'], timestamp)
    build_params.append(("StelligentDemoDBName", db_name))
    #  Create Stack
    sys.stdout.write("Launching CloudFormation Stack in %s..." % args.region)
    sys.stdout.flush()
    create_cfn_stack(connections['cfn'], stack_name, data, build_params)
    print "Done!"
    #  Give Feedback whilst we wait...
    asg_stack_id = get_resource_id(connections['cfn'], stack_name, ASG_STACK,
                                   wait=False)
    asg_id = get_resource_id(connections['cfn'], asg_stack_id, WEB_ASG_NAME)
    #  Setup CodeDeploy
    create_codedeploy_application(connections['codedeploy'],
                                  CAN)
    create_codedeploy_deployment_group(connections['codedeploy'],
                                       CAN, CGN, asg_id, role_arn)
    jenkins_stack_id = get_resource_id(connections['cfn'], stack_name,
                                       JENKINS_STACK, wait=False)
    get_resource_id(connections['cfn'], jenkins_stack_id, JENKINS_INSTANCE)
    get_resource_id(connections['cfn'], stack_name)
    ''' #  FIXME: Change EB to something other than docker then re-enable
    #  Wait for Elastic Beanstalk
    get_resource_id(connections['cfn'], eb_stack)
    '''
    print "Gathering Stack Outputs...almost there!"
    main_outputs = get_stack_outputs(connections['cfn'], stack_name)
    #  FIXME: Change EB to something other than docker then re-enable
    #  eb_outputs = get_stack_outputs(connections['cfn'], eb_stack)
    ecs_outputs = get_stack_outputs(connections['cfn'], ecs_stack)
    #  FIXME: Change EB to something other than docker then re-enable
    #  outputs = main_outputs + eb_outputs + ecs_outputs
    outputs = main_outputs + ecs_outputs
    outputs = sorted(outputs, key=lambda k: k.key)
    #  Upload index.html to transient demo bucket
    create_and_upload_index_to_s3(connections['s3'], outputs)
    print "Outputs:"
    for output in outputs:
        print '%s = %s' % (output.key, output.value)


def destroy(connections, args):
    stacks = list_and_get_stacks(connections['cfn'], allow_all=True)
    for stack in stacks:
        stack, stack_type = stack
        if stack.stack_status == "DELETE_IN_PROGRESS":
            print "Stack %s deletion already in progress." % stack.stack_name
            continue
        if stack_type == 'S3':
            outputs = {x.key: x.value for x in stack.outputs}
            try:
                s3_bucket = outputs[DEMO_S3_BUCKET]
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
            IRN = "-".join((IAM_ROLE_NAME, args.region, hash_id))
            IPN = "-".join((IAM_POLICY_NAME, args.region, hash_id))
            delete_iam_policy(connections['iam'], IRN, IPN)
            delete_iam_role(connections['iam'], IRN)
            #  Destroy EC2 Key Pair
            delete_ec2_key_pair(connections['ec2'], parameters['KeyName'])
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
    if sys.version_info[:3] > (2, 7, 8):
        print "There is currently an SSL issue with Python 2.7.9 and newer."
        print "Please setup a virtualenv with Python 2.7.8 or less to proceed."
        sys.exit(1)
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
    parser.add_argument('-u', '--user', action="store", dest="jenkins_user",
                        default=JENKINS_USER, help="Username for Jenkins")
    parser.add_argument('-e', '--email', action="store", dest="jenkins_email",
                        default=JENKINS_EMAIL, help="Email for Jenkins")
    parser.add_argument('-p', '--password', action="store_true",
                        dest="password_prompt",
                        help="Prompt for Jenkins Password")
    parser.add_argument('--full', action='store_true',
                        help="Always build all components. (VPC, RDS, etc.)")
    parser.add_argument('--warm', action='store_true',
                        help="Only build VPC, SG, and RDS")
    args = parser.parse_args()
    if args.password_prompt:
        print "WARNING: Password will be passed to CFN in plain text."
        args.jenkins_password = getpass.getpass()
    else:
        args.jenkins_password = JENKINS_PASSWORD
    connections = dict()
    connections['cfn'] = cfn_connect(args.region)
    if args.action == "info":
        info(connections)
        sys.exit(0)
    connections['codedeploy'] = codedeploy_connect(args.region)
    connections['ec2'] = ec2_connect(args.region)
    connections['iam'] = iam_connect(args.region)
    connections['s3'] = s3_connect(args.region)
    if args.action == "test":
        #  Test pieces here
        sys.exit(0)
    if args.action == "build":
        if not args.locations:
            print "Please provide at least one IP Address."
            parser.print_help()
            sys.exit(1)
        build(connections, args)
    elif args.action == "destroy":
        destroy(connections, args)


if __name__ == '__main__':
    main()
