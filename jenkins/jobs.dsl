freeStyleJob ('dumpXML') {
	steps {
		shell('echo && echo seed && cat /var/lib/jenkins/jobs/seed/config.xml && echo && echo')
		shell('for job in $(ls /var/lib/jenkins/jobs/); do echo $job; cat /var/lib/jenkins/jobs/$job/config.xml; echo ; done')
	}
}

freeStyleJob ('CodeDeployStage') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('commitID=$(git rev-parse --verify HEAD) && aws deploy create-deployment --output text --application-name nando-demo --region us-east-1 --github-location commitId=$commitID,repository="stelligent/nando_automation_demo" --deployment-group-name nando-demo')
	}
	publishers {
		downstream('CodeDeployStageTests', thresholdName = 'SUCCESS')
	}
}

freeStyleJob ('CodeDeployProduction') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
}

freeStyleJob ('DockerProduction') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
}

freeStyleJob ('CodeDeployStageTests') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
}

freeStyleJob ('DockerStageTests') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
}

freeStyleJob ('DockerStage') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
}
