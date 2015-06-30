// Image Selector Application (ISA)(CodeDeploy)
// ISA Commit
freeStyleJob ('ISA-poll-version-control') {
	scm {
		git('https://github.com/stelligent/stelligent_demo', 'master')
	}
	triggers {
		scm('* * * * *')
	}
	steps {
        customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-run-application-build', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Commit', 'poll-version-control')
}

freeStyleJob ('ISA-run-application-build') {
	steps {
        customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-store-distros', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Commit', 'run-application-build')
}

freeStyleJob ('ISA-store-distros') {
	steps {
        customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-run-unit-tests', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Commit', 'store-distros')
}

freeStyleJob ('ISA-run-unit-tests') {
	steps {
        customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-run-static-analysis', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Commit', 'run-unit-tests')
}

freeStyleJob ('ISA-run-static-analysis') {
	steps {
        customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-provision-environment', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Commit', 'run-static-analysis')
}

//ISA Acceptance Testing
freeStyleJob ('ISA-provision-environment') {
	steps {
        customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-node-configuration', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Acceptance Testing', 'provision-environment')
}

freeStyleJob ('ISA-node-configuration') {
	steps {
        customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-create-system-image', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Acceptance Testing', 'node-configuration')
}

freeStyleJob ('ISA-create-system-image') {
	steps {
        customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-app-deployment', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Acceptance Testing', 'create-system-image')
}

freeStyleJob ('ISA-app-deployment') {
	steps {
        customWorkspace('codedeploy')
		shell('/usr/bin/python codedeploy/codedeploy.py')
	}
	publishers {
        downstream('ISA-run-infrastructure-tests', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Acceptance Testing', 'app-deployment')
}

freeStyleJob ('ISA-run-infrastructure-tests') {
	steps {
        customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
		downstream('ISA-run-long-running-tests', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Acceptance Testing', 'run-infrastructure-tests')
}

freeStyleJob ('ISA-run-long-running-tests') {
	steps {
		customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
		downstream('ISA-approve-reject-exploratory', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Acceptance Testing', 'run-long-running-tests')
}

// ISA Exploratory
freeStyleJob ('ISA-approve-reject-exploratory') {
	steps {
		customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
		downstream('ISA-launch-environment-capacity', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Exploratory', 'approve-reject-exploratory')
}

// ISA Capacity
freeStyleJob ('ISA-launch-environment-capacity') {
	steps {
		customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
		downstream('ISA-load-prod-database-cap', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Capacity', 'launch-env-capacity')
}

freeStyleJob ('ISA-load-prod-database-cap') {
	steps {
		customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
		downstream('ISA-run-loadperf-tests', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Capacity', 'load-prod-database')
}

freeStyleJob ('ISA-run-loadperf-tests') {
	steps {
		customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
		downstream('ISA-run-chaos-tests', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Capacity', 'run-loadperf-tests')
}

freeStyleJob ('ISA-run-chaos-tests') {
	steps {
		customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
		downstream('ISA-dynamic-security-analysis', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Capacity', 'run-chaos-tests')
}

freeStyleJob ('ISA-dynamic-security-analysis') {
	steps {
		customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
		downstream('ISA-terminate-environment-capacity', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Capacity', 'dynamic-security-analysis')
}

freeStyleJob ('ISA-terminate-environment-capacity') {
	steps {
		customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
		downstream('ISA-launch-preprod-environment', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Capacity', 'terminate-env-capacity')
}

// ISA Pre-Production

freeStyleJob ('ISA-launch-preprod-environment') {
	steps {
		customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
		downstream('ISA-load-prod-database', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Pre-Production', 'launch-preprod-env')
}

freeStyleJob ('ISA-load-prod-database') {
	steps {
		customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
		downstream('ISA-blue-green-deployment', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Pre-Production', 'load-prod-database')
}

freeStyleJob ('ISA-blue-green-deployment') {
	steps {
		customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
		downstream('ISA-approve-reject-preprod', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Pre-Production', 'blue-green-deployment')
}



freeStyleJob ('ISA-approve-reject-preprod') {
	steps {
		customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
		downstream('ISA-terminate-preprod', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Pre-Production', 'approve-reject-preprod')
}

freeStyleJob ('ISA-terminate-preprod') {
	steps {
		customWorkspace('codedeploy')
		shell('sleep 2')
	}
	publishers {
		downstream('ISA-update-dns', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Pre-Production', 'terminate-preprod')
}

// ISA Production
freeStyleJob ('ISA-update-dns') {
	steps {
		customWorkspace('codedeploy')
		shell('sleep 2')
	}
	deliveryPipelineConfiguration('Production', 'update-dns')
}
