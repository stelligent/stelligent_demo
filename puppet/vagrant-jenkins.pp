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

	jenkins::job { 'GetInstagramImages':
  		config => template("/etc/puppet/manifests/jobGetInstagramImages.xml.erb"),
	}
        jenkins::job { 'PublishCodeDeploy':
                config => template("/etc/puppet/manifests/jobPublishCodeDeploy.xml.erb"),
        }
}
