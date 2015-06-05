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
    steps {
        customWorkspace('instagram')
        shell('python instagram/instagram.image.test.py')
    }
	publishers {
        downstream('InstagramImageSave', 'SUCCESS')
	}
}
freeStyleJob ('InstagramImageSave') {
    steps {
        customWorkspace('instagram')
        shell('python instagram/instagram.image.save.py')
    }
}
