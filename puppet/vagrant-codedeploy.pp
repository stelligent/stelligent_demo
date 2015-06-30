node /^stelligent-demo-codedeploy.*/ {

	
	Exec { path => "/bin:/sbin:/usr/bin:/usr/sbin" }

	File { backup => puppet }

	filebucket { puppet: server => localhost }

	file { "/etc/cfn": ensure => "directory" }

	class { 'phpfpm': }

	class { 'nginx': }

	file { "StelligentDemoDBName":
		path	=> "/etc/cfn/StelligentDemoDBName",
      		ensure  => present,
      		mode    => 0400,
		source	=> "/vagrant/mysql/StelligentDemoDBName",
		owner	=> "nginx",
		require => [ File['/etc/cfn'], Class['nginx'] ]
    	}

        file { "StelligentDemoDBUser":
                path    => "/etc/cfn/StelligentDemoDBUser",
                ensure  => present,
                mode    => 0400,
		source	=> "/vagrant/mysql/StelligentDemoDBUser",
                owner   => "nginx",
                require => [ File['/etc/cfn'], Class['nginx'] ]
        }

        file { "StelligentDemoDBPass":
                path    => "/etc/cfn/StelligentDemoDBPass",
                ensure  => present,
                mode    => 0400,
		source	=> "/vagrant/mysql/StelligentDemoDBPass",
                owner   => "nginx",
                require => [ File['/etc/cfn'], Class['nginx'] ]
        }

        file { "StelligentDemoDBHost":
                path    => "/etc/cfn/StelligentDemoDBHost",
                ensure  => present,
                mode    => 0400,
		source	=> "/vagrant/mysql/StelligentDemoDBHost",
                owner   => "nginx",
                require => [ File['/etc/cfn'], Class['nginx'] ]
        }

        file { "StelligentDemoDBPort":
                path    => "/etc/cfn/StelligentDemoDBPort",
                ensure  => present,
                mode    => 0400,
		source	=> "/vagrant/mysql/StelligentDemoDBPort",
                owner   => "nginx",
                require => [ File['/etc/cfn'], Class['nginx'] ]
        }
	
  	nginx::resource::vhost { "stelligent-demo":
    		ensure                => present,
    		listen_port           => 80,
    		www_root              => "/var/www/html",
    		index_files           => [ 'index.php' ],
  	}

	nginx::resource::location { "${name}_root":
		ensure          => present,
		www_root        => "/var/www/html",
		vhost		=> "stelligent-demo",
     		location        => '~ \.php$',
     		index_files     => ['index.php', 'index.html', 'index.htm'],
     		proxy           => undef,
     		fastcgi         => "127.0.0.1:9000",
     		fastcgi_script  => undef,
     		location_cfg_append => {
      			fastcgi_connect_timeout => '3m',
       			fastcgi_read_timeout    => '3m',
       			fastcgi_send_timeout    => '3m'
		}
     	}


	phpfpm::pool { 'www': 
		user   	=> 'nginx', 
		require	=> Class['nginx']
	}

	package { 'php-mysql':
    		ensure 	=> installed,
		require	=> Class['phpfpm']
	} 

	#exec { 'chowndocroot':
	#	command	=> "chown -c nginx /var/www/html",
	#	require => Class['nginx']
	#}
	#exec { 'chmoddocroot':
	#	command	=> "chmod -c 0755 /var/www/html",
	#}
}
