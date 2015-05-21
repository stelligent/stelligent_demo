#!/usr/bin/env python

import argparse
import json
import os
import socket
import sys
import zipfile
from datetime import datetime

import boto
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
    s3_connection = boto.connect_s3()
    s3_bucket = s3_connection.get_bucket(MAIN_S3_BUCKET)
    s3_key = S3Key(s3_bucket)
    for f in FILES_TO_S3:
        s3_key.key = os.path.basename(f)
        s3_key.set_contents_from_file(f)


def build(region, locations):
    stack_name = "nando-demo-%s" % datetime.now().strftime('%Y%m%d%H%M%S')
    #copy_files_to_s3()
    with open(CFN_TEMPLATE) as data_file:
        data = json.load(data_file)
    #cfn_connection = boto.connect_cloudformation()
    #import ipdb; ipdb.set_trace()


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
