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
		shell('bash codedeploy/codedeploy.sh')
		shell('sleep 10')
	}
	publishers {
                downstream('CodeDeployStageTests', 'SUCCESS')
	}
}

freeStyleJob ('CodeDeployStageTests') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('sleep 10')
	}
	publishers {
                downstream('CodeDeployProduction', 'SUCCESS')
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

freeStyleJob ('tester') {
}
