freeStyleJob ('dumpXML') {
	steps {
		shell('echo && echo seed && cat /var/lib/jenkins/jobs/seed/config.xml && echo && echo')
		shell('for job in $(ls /var/lib/jenkins/jobs/); do echo $job; cat /var/lib/jenkins/jobs/$job/config.xml; echo ; done')
	}
}

freeStyleJob ('CodeDeployProduction') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
}

freeStyleJob ('CodeDeployStage') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('commitID=$(git rev-parse --verify HEAD) && aws deploy create-deployment --output text --application-name nando-demo --region us-east-1 --github-location commitId=$commitID,repository="stelligent/nando_automation_demo" --deployment-group-name nando-demo')
	        downstreamParameterized {
            		trigger("CodeDeployStageTests", 'SUCCESS', true)
        	}		
	}
}

freeStyleJob ('CodeDeployStageTests') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	        downstreamParameterized {
            		trigger("CodeDeployProduction", 'SUCCESS', true)
        	}		
	}
}

freeStyleJob ('DockerProduction') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
}

freeStyleJob ('DockerStage') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	        downstreamParameterized {
            		trigger("DockerStageTests", 'SUCCESS', true)
        	}		
	}
}

freeStyleJob ('DockerStageTests') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	        downstreamParameterized {
            		trigger("DockerProduction", 'SUCCESS', true)
        	}		
	}
}

