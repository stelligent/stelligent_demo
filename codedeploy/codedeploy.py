#!/usr/bin/python

import sys
import time
import ConfigParser

from subprocess import PIPE, Popen
from boto.codedeploy import connect_to_region as codedeploy_connect
from boto.cloudformation import connect_to_region as cfn_connect

CFN_HUP_LOCATION = '/etc/cfn/cfn-hup.conf'
GITHUB_REPOSITORY = 'stelligent/stelligent_demo'
TIMEOUT = 600
SLEEP_SECONDS = 10


def get_stack_config(config_file):
    config = ConfigParser.ConfigParser()
    config.read(config_file)
    return config.get('main', 'region'), config.get('main', 'stack')


def get_codedeploy_app_and_group(connection, arn):
    stack = connection.describe_stacks(arn)[0]
    parameters = {x.key: x.value for x in stack.parameters}
    return {'application': parameters['CodeDeployAppName'],
            'group': parameters['CodeDeployDeploymentGroup']}


def get_git_commit_id():
    git_command = ['/usr/bin/git', 'rev-parse', '--verify', 'HEAD']
    process = Popen(git_command, stdout=PIPE, stderr=PIPE)
    output, error = process.communicate()
    return output.rstrip()


def main():
    # Fetch our region and stack arn written during the cfn deployment
    region, stack_arn = get_stack_config(CFN_HUP_LOCATION)

    # Make our AWS connections
    connections = dict()
    connections['cfn'] = cfn_connect(region)
    connections['codedeploy'] = codedeploy_connect(region)

    # Fetch the codedeploy details from the cfn stack arn
    codedeploy = get_codedeploy_app_and_group(connections['cfn'], stack_arn)

    # Get the latest git revision number
    commit_id = get_git_commit_id()

    # Create the codedeploy deployment
    revision = {
                    'revisionType': 'GitHub',
                    'gitHubLocation': {
                        'repository': GITHUB_REPOSITORY,
                        'commitId': commit_id
                    }
               }
    deploy_result = connections['codedeploy'].create_deployment(
        codedeploy['application'],
        codedeploy['group'],
        revision
    )

    # Wait for deployment to complete before we exit
    # Any suggestions to improve this code block are welcome
    cnt = 0
    done = False
    while (not done):
        deployment = connections['codedeploy'].get_deployment(deploy_result['deploymentId'])
        status = deployment['deploymentInfo']['status']

        if (cnt >= TIMEOUT):
            sys.stderr.write("Deployment failed to finish before %d minutes "
                             "timeout period.\n" % (TIMEOUT * 10))
            sys.exit(1)
        if status == "Failed":
            sys.stderr.write("Deployment returning FAILED status!\n")
            sys.exit(1)
        if status == "Succeeded":
            done = True

        time.sleep(SLEEP_SECONDS)
        cnt = cnt + SLEEP_SECONDS

    print "Deployment completed"


if __name__ == '__main__':
    main()
