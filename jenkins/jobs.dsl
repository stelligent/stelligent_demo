freeStyleJob ('InstagramImageGet') {
	scm {
                git('https://github.com/stelligent/nando_automation_demo')
        }
        triggers {
                cron('*/5 * * * *')
        }
        steps {
		customWorkspace('instagram')
                shell('python instagram.image.get.py')
        }
	publishers {
                downstream('InstgramImageTest', 'SUCCESS')
	}
}
freeStyleJob ('InstagramImageTest') {
        scm {
                git('https://github.com/stelligent/nando_automation_demo')
        }
        steps {
                customWorkspace('instagram')
                shell('python instagram.image.test.py')
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
                shell('python instagram.image.save.py')
        }
}
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
		shell('sleep 10')
	}
}

freeStyleJob ('CodeDeployStage') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	triggers {
		scm('* * * * *')
	}
	steps {
		shell('commitID=$(git rev-parse --verify HEAD) && aws deploy create-deployment --output text --application-name nando-demo --region us-east-1 --github-location commitId=$commitID,repository="stelligent/nando_automation_demo" --deployment-group-name nando-demo')
		shell('sleep 10')
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
		shell('sleep 10')
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
		shell('sleep 10')
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
		shell('sleep 10')
        	downstreamParameterized {
            		trigger("DockerProduction", 'SUCCESS', true)
        	}		
	}
}

