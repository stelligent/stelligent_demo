freeStyleJob ('InstagramImageGet') {
	scm {
        git('https://github.com/stelligent/nando_automation_demo')
    }
    triggers {
        cron('*/5 * * * *')
    }
    steps {
        customWorkspace('instagram')
        shell('/usr/local/bin/python2.7 instagram/instagram.image.get.py')
    }
	publishers {
        downstream('InstagramImageTest', 'SUCCESS')
	}
}
freeStyleJob ('InstagramImageTest') {
    scm {
        git('https://github.com/stelligent/nando_automation_demo')
    }
    steps {
        customWorkspace('instagram')
        shell('python instagram/instagram.image.test.py')
    }
	publishers {
        downstream('InstagramImageSave', 'SUCCESS')
	}
}
freeStyleJob ('InstagramImageSave') {
    scm {
        git('https://github.com/stelligent/nando_automation_demo')
    }
    steps {
        customWorkspace('instagram')
        shell('python instagram/instagram.image.save.py')
    }
}
freeStyleJob ('dumpXML') {
	steps {
		shell('echo && echo seed && cat /var/lib/jenkins/jobs/seed/config.xml && echo && echo')
		shell('for job in $(ls /var/lib/jenkins/jobs/); do echo $job; cat /var/lib/jenkins/jobs/$job/config.xml; echo ; done')
	}
}
// Image Selector Application (ISA)(CodeDeploy)
// ISA Commit
freeStyleJob ('ISA-poll-version-control') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	triggers {
		scm('* * * * *')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-run-application-build', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Commit', 'poll-version-control')
}

freeStyleJob ('ISA-run-application-build') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-store-distros', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Commit', 'run-application-build')
}

freeStyleJob ('ISA-store-distros') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-run-unit-tests', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Commit', 'store-distros')
}

freeStyleJob ('ISA-run-unit-tests') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-run-static-analysis', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Commit', 'run-unit-tests')
}

freeStyleJob ('ISA-run-static-analysis') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-launch-environment-acceptance', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Commit', 'run-static-analysis')
}

//ISA Acceptance Testing
freeStyleJob ('ISA-launch-environment-acceptance') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('bash codedeploy/codedeploy.sh')
	}
	publishers {
        downstream('ISA-app-deployment', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Acceptance Testing', 'launch-environment-acceptance')
}

freeStyleJob ('ISA-app-deployment') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-run-infrastructure-tests', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Acceptance Testing', 'app-deployment')
}

freeStyleJob ('ISA-run-infrastructure-tests') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-run-long-running-tests', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Acceptance Testing', 'run-infrastructure-tests')
}

freeStyleJob ('ISA-run-long-running-tests') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-generate-documentation', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Acceptance Testing', 'run-long-running-tests')
}

freeStyleJob ('ISA-generate-documentation') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-create-system-image-acceptance', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Acceptance Testing', 'generate-documentation')
}

freeStyleJob ('ISA-create-system-image-acceptance') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-terminate-environment-acceptance', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Acceptance Testing', 'create-system-image-acceptance')
}

freeStyleJob ('ISA-terminate-environment-acceptance') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-approve-reject-exploratory', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Acceptance Testing', 'terminate-environment-acceptance')
}

// ISA Exploratory
freeStyleJob ('ISA-approve-reject-exploratory') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-launch-environment-capacity', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Exploratory', 'approve-reject-exploratory')
}

// ISA Capacity
freeStyleJob ('ISA-launch-environment-capacity') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-load-prod-database-cap', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Capacity', 'launch-environment-capacity')
}

freeStyleJob ('ISA-load-prod-database-cap') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-run-loadperf-tests', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Capacity', 'load-prod-database')
}

freeStyleJob ('ISA-run-loadperf-tests') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-run-chaos-tests', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Capacity', 'run-loadperf-tests')
}

freeStyleJob ('ISA-run-chaos-tests') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-dynamic-security-analysis', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Capacity', 'run-chaos-tests')
}

freeStyleJob ('ISA-dynamic-security-analysis') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-terminate-environment-capacity', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Capacity', 'dynamic-security-analysis')
}

freeStyleJob ('ISA-terminate-environment-capacity') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-launch-preprod-environment', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Capacity', 'terminate-environment-capacity')
}

// ISA Pre-Production

freeStyleJob ('ISA-launch-preprod-environment') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-load-prod-database', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Pre-Production', 'launch-preprod-environment')
}

freeStyleJob ('ISA-load-prod-database') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-blue-green-deployment', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Pre-Production', 'load-prod-database')
}

freeStyleJob ('ISA-blue-green-deployment') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-approve-reject-preprod', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Pre-Production', 'blue-green-deployment')
}



freeStyleJob ('ISA-approve-reject-preprod') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-terminate-preprod', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Pre-Production', 'approve-reject-preprod')
}

freeStyleJob ('ISA-terminate-preprod') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-update-dns', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Pre-Production', 'terminate-preprod')
}

// ISA Production
freeStyleJob ('ISA-update-dns') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	deliveryPipelineConfiguration('Production', 'update-dns')
}


freeStyleJob ('DockerProduction') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 10')
	}
}

freeStyleJob ('DockerStage') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	triggers {
		scm('* * * * *')
	}
	steps {
		shell('cd docker && bash docker.sh')
		shell('sleep 10')
	}
	publishers {
                downstream('DockerStageTests', 'SUCCESS')
	}
}

freeStyleJob ('DockerStageTests') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 10')
	}
	publishers {
                downstream('DockerProduction', 'SUCCESS')
	}
}

deliveryPipelineView('Continuous Delivery Pipeline') {
    pipelineInstances(3)
    columns(1)
    updateInterval(5)
    enableManualTriggers()
    pipelines {
        component('Image Selector Application', 'ISA-poll-version-control')
        component('Image Slide Show', 'DockerStage')
        component('Instagram Image Processing', 'InstagramImageGet')
    }
}
