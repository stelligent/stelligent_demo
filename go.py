#!/usr/bin/env python

import argparse
import hashlib
import json
import os
import socket
import sys
import time
import zipfile
from datetime import datetime
from pprint import pprint
from time import sleep

from boto import connect_iam as iam_connect, connect_s3 as s3_connect
from boto.cloudformation import connect_to_region as cfn_connect
from boto.codedeploy import connect_to_region as codedeploy_connect
from boto.ec2 import connect_to_region as ec2_connect
from boto.exception import BotoServerError
from boto.s3.key import Key as S3Key

STACK_NAME_PREFIX = 'nando-demo'
DEFAULT_REGION = 'us-east-1'
MAIN_S3_BUCKET = 'nando-automation-demo'  # Permanent S3 Bucket
DOCKER_ZIPFILE = 'nando-demo.zip'
DOCKER_FILES = ['Dockerfile', 'application.py', 'requirements.txt']
FILES_TO_S3 = ['jenkins/seed.xml.erb',
               'puppet/installJenkins.pp',
               'puppet/installJenkinsJob.pp',
               'puppet/installJenkinsPlugins.pp',
               'puppet/installJenkinsUsers.pp',
               'puppet/installJenkinsSecurity.pp',
               DOCKER_ZIPFILE]
CFN_TEMPLATE = 'cloudformation-py.json'
INGRESS_PORTS = ['22', '2222', '8080']
ALLOWED_ACTIONS = ["build", "destroy", "info", "test"]

#  FIXME: These are hard-coded elsewhere, make dynamic everywhere.
CODEDEPLOY_APP_NAME = 'nando-demo'
CODEDEPLOY_GROUP_NAME = 'nando-demo'


#  Note: IAM_ROLE_NAME and IAM_POLICY_NAME will have the region and hash
#        appended as 'NandoDemoRole-us-east-1' to allow multi-region support
IAM_ROLE_NAME = 'NandoDemoCodeDeployRole'
IAM_ROLE_DOC = 'codedeploy/NandoDemoCodeDeployRole.json'
IAM_POLICY_NAME = 'NandoDemoCodeDeployPolicy'
IAM_POLICY_DOC = 'codedeploy/NandoDemoCodeDeployPolicy.json'

#  Resource Logical IDs
JENKINS_INSTANCE = "NandoDemoJenkins"
WEB_ASG_NAME = 'NandoDemoWebASG'
DEMO_RDS = 'NandoDemoMysql'
DEMO_ELB = 'NandoDemoELB'
DEMO_S3_BUCKET = 'NandoDemoBucket'  # Ephemeral Bucket
DEMO_VPC = 'NandoDemoVPC'


def ip_address_type(location):
    try:
        socket.inet_aton(location)
    except:
        raise argparse.ArgumentTypeError("%s is not a valid IP Address" %
                                         location)
    else:
        return location


def list_and_get_stack(cfn_connection, region):
    stacks = cfn_connection.describe_stacks()
    stacks = [stack for stack in stacks if
              stack.stack_name.startswith(STACK_NAME_PREFIX)]
    response = 0
    custom_range = range(1, len(stacks)+1)
    while response not in custom_range:
        for index, stack in enumerate(stacks):
            print "%s) %s" % (index + 1, stack.stack_name)

        response = raw_input("Which stack?  ")
        if response in ['q', 'quit', 'exit']:
            sys.exit(0)
        try:
            response = int(response)
        except ValueError:
            pass
    return stacks[response - 1]


def prepare_docker_zip():
    sys.stdout.write("Repacking %s..." % DOCKER_ZIPFILE)
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
    s3_bucket = s3_connection.get_bucket(bucket)
    s3_key = S3Key(s3_bucket)
    for f in FILES_TO_S3:
        s3_key.key = os.path.basename(f)
        with open(f) as f:
            s3_key.set_contents_from_file(f)
    print "Done!"


def delete_stack_name_from_s3(s3_connection, bucket, target):
    s3_bucket = s3_connection.get_bucket(bucket)
    s3_key = S3Key(s3_bucket)
    s3_key = target
    s3_bucket.delete_key(s3_key)
    print "Deleted stack name from s3 %s." % target


def inject_locations(locations, data):
    sys.stdout.write("Setting security source(s) to %s..." % locations)
    for location in locations:
        # Add CIDR Subnet
        if location == '0.0.0.0':
            location = '%s/0' % location
        else:
            location = '%s/32' % location
        for port in INGRESS_PORTS:
            item = {'IpProtocol': 'tcp',
                    'FromPort': port,
                    'ToPort': port,
                    'CidrIp': '%s' % location}
            data['Resources']['NandoDemoPublicSecurityGroup']['Properties']['SecurityGroupIngress'].append(item)
        data['Resources']['NandoDemoBucketPolicy']['Properties']['PolicyDocument']['Statement'][0]['Condition']['IpAddress']['aws:SourceIp'].append(location)
    print "Done!"
    return data


def get_instagram_keys_from_env():
    try:
        insta_id = os.environ['INSTAGRAM_CLIENT_ID']
        insta_secret = os.environ['INSTAGRAM_CLIENT_SECRET']
    except KeyError:
        print "Please set both 'INSTAGRAM_CLIENT_ID' and " \
              "'INSTAGRAM_CLIENT_SECRET' in your environment."
        sys.exit(1)
    else:
        return insta_id, insta_secret


def create_ec2_key_pair(ec2_connection, key_pair_name):
    sys.stdout.write("Creating EC2 Key Pair %s..." % key_pair_name)
    kp = ec2_connection.create_key_pair(key_pair_name)
    print "Done!"
    sys.stdout.write("Creating private key %s.pem locally..." % key_pair_name)
    kp.save('.')
    print "Done!"
    return kp.material


def delete_ec2_key_pair(ec2_connection, key_pair_name):
    sys.stdout.write("Deleting EC2 Key Pair %s..." % key_pair_name)
    ec2_connection.delete_key_pair(key_pair_name)
    print "Done!"
    key_file = '%s.pem' % key_pair_name
    if os.path.isfile(key_file):
        os.remove(key_file)
        print "Deleted Private Key %s." % key_file


def create_iam_role(iam_connection, role_name, role_doc):
    sys.stdout.write("Creating IAM Role %s..." % role_name)
    with open(role_doc) as doc:
        result = iam_connection.create_role(
            role_name, assume_role_policy_document=doc.read())
    print "Done!"
    return result['create_role_response']['create_role_result']['role']['arn']


def delete_iam_role(iam_connection, role_name):
    sys.stdout.write("Deleting IAM Role %s..." % role_name)
    iam_connection.delete_role(role_name)
    print "Done!"


def put_iam_role_policy(iam_connection, role_name, policy_name,
                        policy_doc):
    sys.stdout.write("Adding policy %s ..." % policy_name)
    with open(policy_doc) as doc:
        iam_connection.put_role_policy(role_name, policy_name, doc.read())
    print "Done!"


def delete_iam_policy(iam_connection, role_name, policy_name):
    sys.stdout.write("Deleting policy %s..." % policy_name)
    iam_connection.delete_role_policy(role_name, policy_name)
    print "Done!"


def create_codedeploy_application(codedeploy_connection, app_name):
    sys.stdout.write("Creating CodeDeploy Application %s..." % app_name)
    codedeploy_connection.create_application(app_name)
    print "Done!"


def delete_codedeploy_application(codedeploy_connection, app_name):
    sys.stdout.write("Deleting CodeDeploy Application %s..." % app_name)
    codedeploy_connection.delete_application(app_name)
    print "Done!"


def create_codedeploy_deployment_group(codedeploy_connection, app_name,
                                       group_name, asg_id, service_role):
    sys.stdout.write("Creating CodeDeploy Deployment Group %s..." % group_name)
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
    codedeploy_connection.delete_deployment_group(app_name, group_name)
    print "Done!"


def empty_related_buckets(s3_connection, stack, bucket_name=DEMO_S3_BUCKET):
    #  Safeguard. Do not delete items from main bucket.
    if bucket_name == MAIN_S3_BUCKET:
        return
    resource = stack.describe_resource(bucket_name)
    bucket_id = resource['DescribeStackResourceResponse']['DescribeStackResourceResult']['StackResourceDetail'].get('PhysicalResourceId')
    bucket = s3_connection.get_bucket(bucket_id)
    keys = bucket.get_all_keys()
    if keys:
        print "Deleting the following files from %s:" % bucket_id
        print keys
        bucket.delete_keys(keys)


def get_resource_id(cfn_connection, stack_name, resource_name):
    #  Initial Check
    try:
        #  FIXME: Must be a better way...
        resource = cfn_connection.describe_stack_resource(stack_name,
                                                          resource_name)
        info = resource['DescribeStackResourceResponse']['DescribeStackResourceResult']['StackResourceDetail']
        status = info['ResourceStatus']
        resource_id = info['PhysicalResourceId']
    except BotoServerError:
        status = "NOT STARTED"
    while status != "CREATE_COMPLETE":
        sys.stdout.write("\rWaiting for %s        " % resource_name)
        sys.stdout.flush()
        sleep(1)
        sys.stdout.write("\rWaiting for %s.       " % resource_name)
        sys.stdout.flush()
        sleep(1)
        sys.stdout.write("\rWaiting for %s..      " % resource_name)
        sys.stdout.flush()
        sleep(1)
        sys.stdout.write("\rWaiting for %s...     " % resource_name)
        sys.stdout.flush()
        try:
            #  FIXME: Must be a better way...
            resource = cfn_connection.describe_stack_resource(stack_name,
                                                              resource_name)
            info = resource['DescribeStackResourceResponse']['DescribeStackResourceResult']['StackResourceDetail']
            status = info['ResourceStatus']
            resource_id = info['PhysicalResourceId']
        except BotoServerError:
            status = "NOT STARTED"
        if status.endswith('FAILED'):
            sys.stdout.write("\n")
            print "Stack Failed. Exiting..."
            sys.exit(1)
        if status.endswith('COMPLETE'):
            sys.stdout.write("\rWaiting for %s...Done!" % resource_name)
            sys.stdout.flush()
            sys.stdout.write("\n")
    return resource_id


def set_stack_name_in_s3(s3_connection, stack_name, dest_name, bucket):
    s3_bucket = s3_connection.get_bucket(bucket)
    s3_key = S3Key(s3_bucket)
    s3_key.key = dest_name
    s3_key.set_contents_from_string(stack_name)


def build(connections, region, locations, hash_id):
    build_params = list()
    #  Setup Instagram Access
    instagram_id, instagram_secret = get_instagram_keys_from_env()
    build_params.append(("InstagramId", instagram_id))
    build_params.append(("InstagramSecret", instagram_secret))
    #  Setup Stack
    stack_name = "%s-%s" % (STACK_NAME_PREFIX,
                            datetime.now().strftime('%Y%m%d%H%M%S'))
    build_params.append(("NandoDemoName", stack_name))
    build_params.append(("DemoRegion", region))
    build_params.append(("HashID", hash_id))
    #  Setup S3
    copy_files_to_s3(connections['s3'], MAIN_S3_BUCKET)
    #  Setup Security Groups/Access
    with open(CFN_TEMPLATE) as data_file:
        data = json.load(data_file)
    location_in_data = inject_locations(locations, data)
    #  Setup EC2 Key Pair
    key_pair_name = stack_name
    private_key = create_ec2_key_pair(connections['ec2'], key_pair_name)
    build_params.append(("KeyName", key_pair_name))
    build_params.append(("PrivateKey", private_key))
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
    #  Create Stack
    sys.stdout.write("Launching CloudFormation Stack in %s..." % region)
    connections['cfn'].create_stack(
        stack_name,
        template_body=json.dumps(location_in_data, indent=2),
        parameters=build_params,
        capabilities=['CAPABILITY_IAM'],
        disable_rollback='true'
    )
    #  Upload stackname to S3
    dest_name = "cloudformation.stack.name-%s-%s" % (region, hash_id)
    set_stack_name_in_s3(connections['s3'], stack_name,
                         dest_name, MAIN_S3_BUCKET)
    print "Done!"
    #  Give Feedback whilst we wait...
    get_resource_id(connections['cfn'], stack_name, DEMO_S3_BUCKET)
    get_resource_id(connections['cfn'], stack_name, DEMO_VPC)
    get_resource_id(connections['cfn'], stack_name, DEMO_ELB)
    get_resource_id(connections['cfn'], stack_name, DEMO_RDS)
    asg_id = get_resource_id(connections['cfn'], stack_name, WEB_ASG_NAME)
    #  Setup CodeDeploy
    create_codedeploy_application(connections['codedeploy'],
                                  CAN)
    create_codedeploy_deployment_group(connections['codedeploy'],
                                       CAN, CGN, asg_id, role_arn)
    get_resource_id(connections['cfn'], stack_name, JENKINS_INSTANCE)
    print "Gathering Stack Outputs...almost there!"
    outputs = ''
    while not outputs:
        stack = connections['cfn'].describe_stacks(stack_name)[0]
        outputs = stack.outputs
        if not outputs:
            time.sleep(3)
    print "Outputs:"
    for output in outputs:
        print '%s = %s' % (output.key, output.value)


def destroy(connections, region):
    stack = list_and_get_stack(connections['cfn'], region)
    #  Fetch our Hash ID for this stack (probably a better way to find this)
    for param in stack.parameters:
        if param.key == "HashID":
            hash_id = param.value
    parameters = {x.key: x.value for x in stack.parameters}
    #  Destroy CodeDeploy
    delete_codedeploy_deployment_group(connections['codedeploy'],
                                       parameters['CodeDeployAppName'],
                                       parameters['CodeDeployDeploymentGroup'])
    delete_codedeploy_application(connections['codedeploy'],
                                  parameters['CodeDeployAppName'])
    #  Empty S3 Bucket
    empty_related_buckets(connections['s3'], stack)
    #  Destroy Stack
    sys.stdout.write("Deleting the CloudFormation Stack %s..." %
                     stack.stack_name)
    print "Deleting!"
    connections['cfn'].delete_stack(stack.stack_name)
    #  Destroy IAM Roles/Policies
    IRN = "-".join((IAM_ROLE_NAME, region, hash_id))
    IPN = "-".join((IAM_POLICY_NAME, region, hash_id))
    delete_iam_policy(connections['iam'], IRN, IPN)
    delete_iam_role(connections['iam'], IRN)
    #  Destroy EC2 Key Pair
    delete_ec2_key_pair(connections['ec2'], parameters['KeyName'])
    #  Remove the stackname from S3
    dest_name = "cloudformation.stack.name-%s-%s" % (region, hash_id)
    delete_stack_name_from_s3(connections['s3'], MAIN_S3_BUCKET, dest_name)


def info(connections, region):
    stack = list_and_get_stack(connections['cfn'], region)
    pprint(stack.parameters, indent=2)


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
    args = parser.parse_args()
    connections = dict()
    connections['cfn'] = cfn_connect(args.region)
    if args.action == "info":
        info(connections, args.region)
        sys.exit(0)
    connections['codedeploy'] = codedeploy_connect(args.region)
    connections['ec2'] = ec2_connect(args.region)
    connections['iam'] = iam_connect()
    connections['s3'] = s3_connect()
    if args.action == "test":
        #  Test pieces here
        sys.exit(0)
    if args.action == "build":
        if not args.locations:
            print "Please provide at least one IP Address."
            parser.print_help()
            sys.exit(1)
        build(connections, args.region, args.locations, args.hash_id)
    elif args.action == "destroy":
        destroy(connections, args.region)


if __name__ == '__main__':
    main()
