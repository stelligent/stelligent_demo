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

