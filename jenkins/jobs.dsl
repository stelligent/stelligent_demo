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
freeStyleJob ('ISA-trigger') {
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
        downstream('ISA-commit', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Commit', 'trigger')
}

freeStyleJob ('ISA-commit') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-create-env-acceptance', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Commit', 'commit')
}

//ISA Acceptance Testing

freeStyleJob ('ISA-create-env-acceptance') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('bash codedeploy/codedeploy.sh')
	}
	publishers {
        downstream('ISA-run-tests-infrastructure', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Acceptance Testing', 'create-env-acceptance')
}

freeStyleJob ('ISA-run-tests-infrastructure') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-destroy-env-acceptence', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Acceptance Testing', 'run-tests-infrastructure')
}

freeStyleJob ('ISA-destroy-env-acceptence') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-create-env-exploratory', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Acceptance Testing', 'destroy-env-acceptance')
}

// ISA Exploratory
freeStyleJob ('ISA-create-env-exploratory') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-approve-reject-exploratory', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Exploratory', 'create-env-exploratory')
}

freeStyleJob ('ISA-approve-reject-exploratory') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-destroy-env-exploratory', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Exploratory', 'approve-reject-exploratory')
}

freeStyleJob ('ISA-destroy-env-exploratory') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-create-env-capacity', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Exploratory', 'destroy-env-exploratory')
}

// ISA Capacity
freeStyleJob ('ISA-create-env-capacity') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-run-tests-performance', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Capacity', 'create-env-capacity')
}

freeStyleJob ('ISA-run-tests-performance') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-run-tests-load', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Capacity', 'run-tests-performance')
}

freeStyleJob ('ISA-run-tests-load') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-run-tests-chaos', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Capacity', 'run-tests-load')
}

freeStyleJob ('ISA-run-tests-chaos') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-destroy-env-capacity', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Capacity', 'run-tests-chaos')
}

freeStyleJob ('ISA-destroy-env-capacity') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-create-env-staging', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Capacity', 'destroy-env-capacity')
}


// ISA Pre-Production

freeStyleJob ('ISA-create-env-staging') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-approve-reject-staging', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Pre-Production', 'create-env-staging')
}

freeStyleJob ('ISA-approve-reject-staging') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-destroy-env-staging', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Pre-Production', 'approve-reject-staging')
}

freeStyleJob ('ISA-destroy-env-staging') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-create-env-production', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Pre-Production', 'destroy-env-staging')
}

// ISA Production

freeStyleJob ('ISA-create-env-production') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-approve-reject-production', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Production', 'create-env-production')
}

freeStyleJob ('ISA-approve-reject-production') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	publishers {
        downstream('ISA-blue-green-deployment', 'SUCCESS')
	}
	deliveryPipelineConfiguration('Production', 'approve-reject-production')
}

freeStyleJob ('ISA-blue-green-deployment') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 2')
	}
	deliveryPipelineConfiguration('Production', 'blue-green-deployment')
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
        component('Image Selector Application', 'ISA-trigger')
        component('Image Slide Show', 'DockerStage')
        component('Instagram Image Processing', 'InstagramImageGet')
    }
}
