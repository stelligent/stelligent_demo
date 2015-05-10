node /^nando-demo-jenkins.*/ {

	Exec { path => "/bin:/sbin:/usr/bin:/usr/sbin" }
	
	class { jenkins: lts => true, }

        jenkins::plugin { 'python': }
	jenkins::plugin { 'credentials': }
	jenkins::plugin { 'github': }
	jenkins::plugin { 'ssh-credentials': }
	jenkins::plugin { 'github-api': }
	jenkins::plugin { 'scm-api': }
	jenkins::plugin { 'git-client': }
	jenkins::plugin { 'git': }
	jenkins::plugin { 'parameterized-trigger': }
	jenkins::plugin { 'promoted-builds': }
	jenkins::plugin { 'job-dsl': }
	jenkins::plugin { 'build-flow-plugin': }


	jenkins::job { 'InstagramImageGet':
  		config => template("/etc/puppet/templates/jobInstagramImageGet.xml.erb"),
	}
	jenkins::job { 'InstagramImageTest':
  		config => template("/etc/puppet/templates/jobInstagramImageTest.xml.erb"),
	}
	jenkins::job { 'InstagramImageSave':
  		config => template("/etc/puppet/templates/jobInstagramImageSave.xml.erb"),
	}
        jenkins::job { 'seed':
                config => template("/etc/puppet/templates/seed.xml.erb"),
        }
}
