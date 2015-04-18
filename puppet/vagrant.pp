node 'vagrant-centos65.hex7.com' {

	
	Exec { path => "/bin:/sbin:/usr/bin:/usr/sbin" }
	
	class { nginx: }
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

	class { '::mysql::server':
  		root_password           => 'nando-demo-mysql-root-password',
  		remove_default_accounts => true,
	}
	
	mysql::db { 'nando-demo':
  		user     => 'nando-demo-mysql-user',
  		password => 'nando-demo-mysql-password',
  		host     => 'localhost',
  		grant    => ['SELECT', 'UPDATE'],
	}
}
