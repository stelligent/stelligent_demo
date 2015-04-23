node /^nando-demo-codedeploy.*/ {

	
	Exec { path => "/bin:/sbin:/usr/bin:/usr/sbin" }

	file { "/etc/cfn": ensure => "directory" }

	file { "NandoDemoDBName":
		path	=> "/etc/cfn/NandoDemoDBName",
      		ensure  => present,
      		mode    => 0400,
		source	=> "/vagrant/mysql/NandoDemoDBName",
		owner	=> "nginx",
		require => [ File['/etc/cfn'], Class['nginx'] ]
    	}

        file { "NandoDemoDBUser":
                path    => "/etc/cfn/NandoDemoDBUser",
                ensure  => present,
                mode    => 0400,
		source	=> "/vagrant/mysql/NandoDemoDBUser",
                owner   => "nginx",
                require => [ File['/etc/cfn'], Class['nginx'] ]
        }

        file { "NandoDemoDBPass":
                path    => "/etc/cfn/NandoDemoDBPass",
                ensure  => present,
                mode    => 0400,
		source	=> "/vagrant/mysql/NandoDemoDBPass",
                owner   => "nginx",
                require => [ File['/etc/cfn'], Class['nginx'] ]
        }

        file { "NandoDemoDBHost":
                path    => "/etc/cfn/NandoDemoDBHost",
                ensure  => present,
                mode    => 0400,
		source	=> "/vagrant/mysql/NandoDemoDBHost",
                owner   => "nginx",
                require => [ File['/etc/cfn'], Class['nginx'] ]
        }

        file { "NandoDemoDBPort":
                path    => "/etc/cfn/NandoDemoDBPort",
                ensure  => present,
                mode    => 0400,
		source	=> "/vagrant/mysql/NandoDemoDBPort",
                owner   => "nginx",
                require => [ File['/etc/cfn'], Class['nginx'] ]
        }

	filebucket { '': 
		path	=> "/tmp",
		server => "localhost"; 
	}
	
	class { 'nginx': }

  	nginx::resource::vhost { "nando-automation-demo":
    		ensure                => present,
    		listen_port           => 80,
    		www_root              => "/var/www/html",
    		index_files           => [ 'index.php' ],
  	}

	nginx::resource::location { "${name}_root":
		ensure          => present,
		www_root        => "/var/www/html",
		vhost		=> "nando-automation-demo",
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

	class { 'phpfpm': }

	phpfpm::pool { 'www': 
		user   	=> 'nginx', 
		require	=> Class['nginx']
	}

	package { 'php-mysql':
    		ensure 	=> installed,
		require	=> Class['phpfpm']
	} 

	exec { 'chowndocroot':
		command	=> "chown -c nginx /var/www/html",
		require => Class['nginx']
	}
}
