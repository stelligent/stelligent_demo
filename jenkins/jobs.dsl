freeStyleJob ('dump-XML') {
	scm {
		git(https://github.com/stelligent/nando_automation_demo)
	}
	steps {
		shell('echo "hello world"')
	}
}
