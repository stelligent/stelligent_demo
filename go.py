#!/usr/bin/env python

import argparse
import json
import os
import socket
import sys
import zipfile
from datetime import datetime

from boto import connect_s3 as s3_connect
from boto.cloudformation import connect_to_region as cfn_connect
from boto.ec2 import connect_to_region as ec2_connect
from boto.s3.key import Key as S3Key

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
ALLOWED_ACTIONS = ["build", "destroy", "list"]

def ip_address_type(location):
    try:
        socket.inet_aton(location)
    except:
        raise argparse.ArgumentTypeError("%s is not a valid IP Address" %
                                         location)
    else:
        return location


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


def copy_files_to_s3():
    prepare_docker_zip()
    print "Sending files to S3..."
    s3_connection = s3_connect()
    s3_bucket = s3_connection.get_bucket(MAIN_S3_BUCKET)
    s3_key = S3Key(s3_bucket)
    for f in FILES_TO_S3:
        s3_key.key = os.path.basename(f)
        with open(f) as f:
            s3_key.set_contents_from_file(f)


def inject_locations(locations, data):
    for location in locations:
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

def create_ec2_key_pair(key_pair_name, region):
    ec2_connection = ec2_connect(region)
    kp = ec2_connection.create_key_pair(key_pair_name)
    kp.save('.')
    return kp.material


def build(region, locations):
    insta_id, insta_secret = get_instagram_keys_from_env()
    build_params = list()
    build_params.append(("InstagramId", insta_id))
    build_params.append(("InstagramSecret", insta_secret))
    stack_name = "nando-demo-%s" % datetime.now().strftime('%Y%m%d%H%M%S')
    build_params.append(("NandoDemoName", stack_name))
    key_pair_name = stack_name
    build_params.append(("KeyName", key_pair_name))
    copy_files_to_s3()
    with open(CFN_TEMPLATE) as data_file:
        data = json.load(data_file)
    location_in_data = inject_locations(locations, data)
    private_key = create_ec2_key_pair(key_pair_name, region)
    build_params.append(("PrivateKey", private_key))
    #  Create Stack
    cfn_connection = cfn_connect(region)
    cfn_connection.create_stack(
        stack_name,
        template_body=json.dumps(location_in_data),
        parameters=build_params,
        capabilities=['CAPABILITY_IAM']
    )


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

    if args.action == "build":
        if not args.locations:
            print "Please provide at least one IP Address."
            parser.print_help()
            sys.exit(1)
        build(args.region, args.locations)
    elif args.action == "destroy":
        print "destroy"


if __name__ == '__main__':
    main()
