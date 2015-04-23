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
	jenkins::plugin { 'maven': }
	jenkins::plugin { 'promoted-builds': }
	jenkins::plugin { 'job-dsl': }
	jenkins::plugin { 'build-flow-plugin': }


	jenkins::job { 'InstagramImageGet':
  		config => template("/etc/puppet/manifests/jobInstagramImageGet.xml.erb"),
	}
	jenkins::job { 'InstagramImageTest':
  		config => template("/etc/puppet/manifests/jobInstagramImageTest.xml.erb"),
	}
	jenkins::job { 'InstagramImageSave':
  		config => template("/etc/puppet/manifests/jobInstagramImageSave.xml.erb"),
	}
        jenkins::job { 'DeployStage':
                config => template("/etc/puppet/manifests/jobDeployStage.xml.erb"),
        }
        jenkins::job { 'DeployStageTests':
                config => template("/etc/puppet/manifests/jobDeployStageTests.xml.erb"),
        }
        jenkins::job { 'DeployProduction':
                config => template("/etc/puppet/manifests/jobDeployProduction.xml.erb"),
        }

}
