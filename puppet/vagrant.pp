node 'vagrant-centos65.hex7.com' {

	include nginx
	
	class { jenkins:
		lts => true,
	}

        jenkins::plugin { 'python': }
	jenkins::plugin { 'credentials': }
	jenkins::plugin { 'github': }
	jenkins::plugin { 'ssh-credentials': }
	jenkins::plugin { 'github-api': }
	jenkins::plugin { 'scm-api': }
	jenkins::plugin { 'git-client': }
	jenkins::plugin { 'git': }

	class { jenkins::security:
		security_model => 'full_control',
	}

  	jenkins::user { 'nando':
    		email    => 'fernando.pando@stelligent.com',
    		password => 'changeme123',
  	}

}
