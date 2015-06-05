freeStyleJob ('DockerProduction') {
	steps {
		customWorkspace('docker')
		shell('sleep 10')
	}
}

freeStyleJob ('DockerStage') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo', 'master')
	}
	triggers {
		scm('* * * * *')
	}
	steps {
        customWorkspace('docker')
		shell('cd docker && bash docker.sh')
		shell('sleep 10')
	}
	publishers {
		downstream('DockerStageTests', 'SUCCESS')
	}
}

freeStyleJob ('DockerStageTests') {
	steps {
		customWorkspace('docker')
		shell('sleep 10')
	}
	publishers {
		downstream('DockerProduction', 'SUCCESS')
	}
}

