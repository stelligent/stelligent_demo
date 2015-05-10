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
	steps {
		shell('sleep 360')
	}
}

freeStyleJob ('CodeDeployStage') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('commitID=$(git rev-parse --verify HEAD) && aws deploy create-deployment --output text --application-name nando-demo --region us-east-1 --github-location commitId=$commitID,repository="stelligent/nando_automation_demo" --deployment-group-name nando-demo')
		shell('sleep 30')
	        downstreamParameterized {
            		trigger("CodeDeployStageTests", 'SUCCESS', true)
        	}		
	}
}

freeStyleJob ('CodeDeployStageTests') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 30')
	        downstreamParameterized {
            		trigger("CodeDeployProduction", 'SUCCESS', true)
        	}		
	}
}

freeStyleJob ('DockerProduction') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 360')
	}
}

freeStyleJob ('DockerStage') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 30')
	        downstreamParameterized {
            		trigger("DockerStageTests", 'SUCCESS', true)
        	}		
	}
}

freeStyleJob ('DockerStageTests') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 30')
        	downstreamParameterized {
            		trigger("DockerProduction", 'SUCCESS', true)
        	}		
	}
}

