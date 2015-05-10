freeStyleJob ('dump-XML') {
	scm {
		git('https://github.com/stelligent/nando_automation_demo')
	}
	steps {
		shell('for job in $(ls /var/lib/jenkins/jobs/); do echo $job; cat /var/lib/jenkins/jobs/$job/config.xml; echo ; done')
	}
}
