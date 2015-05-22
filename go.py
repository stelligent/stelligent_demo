#!/usr/bin/env python

import argparse
import json
import os
import socket
import sys
import zipfile
from datetime import datetime
from pprint import pprint

from boto import connect_iam as iam_connect
from boto import connect_s3 as s3_connect
from boto.cloudformation import connect_to_region as cfn_connect
from boto.codedeploy import connect_to_region as codedeploy_connect
from boto.ec2 import connect_to_region as ec2_connect
from boto.s3.key import Key as S3Key

STACK_NAME_PREFIX = 'nando-demo'
DEFAULT_REGION = 'us-east-1'
MAIN_S3_BUCKET = 'nando-automation-demo'
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
IAM_ROLE_NAME = 'NandoDemoCodeDeployRole'
IAM_ROLE_DOC = 'codedeploy/NandoDemoCodeDeployRole.json'
IAM_POLICY_NAME = 'NandoDemoCodeDeployPolicy'
IAM_POLICY_DOC = 'codedeploy/NandoDemoCodeDeployPolicy.json'

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
    print "Repacking %s..." % DOCKER_ZIPFILE
    try:
        os.remove(DOCKER_ZIPFILE)
    except OSError:
        pass
    with zipfile.ZipFile(DOCKER_ZIPFILE, mode='w') as zf:
        os.chdir('docker')
        for f in DOCKER_FILES:
            zf.write(f)
        os.chdir('..')


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


def inject_locations(locations, data):
    for location in locations:
        location += '/32'  # Add CIDR Subnet
        for port in INGRESS_PORTS:
            item = {'IpProtocol': 'tcp',
                    'FromPort': port,
                    'ToPort': port,
                    'CidrIp': '%s' % location}
            data['Resources']['NandoDemoPublicSecurityGroup']['Properties']['SecurityGroupIngress'].append(item)
        data['Resources']['NandoDemoBucketPolicy']['Properties']['PolicyDocument']['Statement'][0]['Condition']['IpAddress']['aws:SourceIp'].append(location)
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
    sys.stdout.write("Creating EC2 KeyPair %s..." % key_pair_name)
    kp = ec2_connection.create_key_pair(key_pair_name)
    kp.save('.')
    print "Done!"
    return kp.material


def delete_ec2_key_pair(ec2_connection, key_pair_name):
    sys.stdout.write("Deleting EC2 KeyPair %s..." % key_pair_name)
    ec2_connection.delete_key_pair(key_pair_name)
    print "Done!"


def create_iam_role(iam_connection, role_name, role_doc):
    sys.stdout.write("Creating IAM Role %s..." % role_name)
    with open(role_doc) as doc:
        iam_connection.create_role(
            role_name, assume_role_policy_document=doc.read())
    print "Done!"


def delete_iam_role(iam_connection, role_name):
    sys.stdout.write("Deleting IAM Role %s..." % role_name)
    iam_connection.delete_role(role_name)
    print "Done!"


def put_iam_role_policy(iam_connection, role_name, policy_name,
                        policy_doc):
    sys.stdout.write("Putting policy %s to role %s..." % (role_name,
                                                          policy_name))
    with open(policy_doc) as doc:
        iam_connection.put_role_policy(role_name, policy_name, doc.read())
    print "Done!"


def delete_iam_policy(iam_connection, role_name, policy_name):
    sys.stdout.write("Deleting policy %s from role %s..." % (role_name,
                                                             policy_name))
    iam_connection.delete_role_policy(role_name, policy_name)
    print "Done!"


def create_codedeploy_application(codedeploy_connection, app_name):
    print "Done!"
    pass


def delete_codedeploy_application(codedeploy_connection, app_name):
    print "Done!"
    pass


def create_codedeploy_deployment_group(codedeploy_connection, app_name,
                                       group_name):
    print "Done!"
    pass


def delete_codedeploy_deployment_group(codedeploy_connection, app_name,
                                       group_name):
    print "Done!"
    pass


def build(connections, region, locations):
    build_params = list()
    #  Setup Instagram Access
    instagram_id, instagram_secret = get_instagram_keys_from_env()
    build_params.append(("InstagramId", instagram_id))
    build_params.append(("InstagramSecret", instagram_secret))
    #  Setup Stack
    stack_name = "%s-%s" % (STACK_NAME_PREFIX,
                            datetime.now().strftime('%Y%m%d%H%M%S'))
    build_params.append(("NandoDemoName", stack_name))
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
    create_iam_role(connections['iam'], IAM_ROLE_NAME, IAM_ROLE_DOC)
    put_iam_role_policy(connections['iam'], IAM_ROLE_NAME, IAM_POLICY_NAME,
                        IAM_POLICY_DOC)
    #  Create Stack
    sys.stdout.write("Launching CloudFormation Stack in %s..." % region)
    connections['cfn'].create_stack(
        stack_name,
        template_body=json.dumps(location_in_data, indent=2),
        parameters=build_params,
        capabilities=['CAPABILITY_IAM'],
        disable_rollback='true'
    )
    print "Done!"

def destroy(connections, region):
    stack = list_and_get_stack(connections['cfn'], region)
    parameters = {x.key: x.value for x in stack.parameters}

    #  Destroy Stack
    sys.stdout.write("Deleting the CloudFormation Stack %s..." %
                     stack.stack_name)
    connections['cfn'].delete_stack(stack.stack_name)
    #  Destroy IAM Roles/Policies
    delete_iam_policy(connections['iam'], IAM_ROLE_NAME, IAM_POLICY_NAME)
    delete_iam_role(connections['iam'], IAM_ROLE_NAME)
    #  Destroy EC2 Key Pair
    delete_ec2_key_pair(connections['ec2'], parameters['KeyName'])
    print "Done!"


def info(connections, region):
    stack = list_and_get_stack(connections['cfn'], region)
    pprint(stack.parameters, indent=2)
    #import ipdb;ipdb.set_trace()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=ALLOWED_ACTIONS, action="store",
                        help="Action to take against the stack(s)")
    parser.add_argument("-l", "--location", nargs='*', action="store",
                        dest="locations", help="""If building, provide the
                        IP Address(es) from which ssh is allowed.\n
                        Example: './go.py build -l xx.xx.xx.xx yy.yy.yy.yy""",
                        type=ip_address_type)
    parser.add_argument('--region', action="store", dest="region",
                        default=DEFAULT_REGION)
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
        print "Testing stuff"
        create_iam_role(connections['iam'], IAM_ROLE_NAME, IAM_ROLE_DOC)
        put_iam_role_policy(connections['iam'], IAM_ROLE_NAME, IAM_POLICY_NAME,
                            IAM_POLICY_DOC)
        raw_input("ok to delete?")
        delete_iam_policy(connections['iam'], IAM_ROLE_NAME, IAM_POLICY_NAME)
        delete_iam_role(connections['iam'], IAM_ROLE_NAME)

        sys.exit(0)
    if args.action == "build":
        if not args.locations:
            print "Please provide at least one IP Address."
            parser.print_help()
            sys.exit(1)
        build(connections, args.region, args.locations)
    elif args.action == "destroy":
        destroy(connections, args.region)


if __name__ == '__main__':
    main()
