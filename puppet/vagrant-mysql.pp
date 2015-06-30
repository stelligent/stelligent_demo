node /^stelligent-demo-mysql.*/ {
  		
	Exec { path => "/bin:/sbin:/usr/bin:/usr/sbin" }
	
	class { '::mysql::server':
	  #root_password    => 'mysql-root-password',
		remove_default_accounts => true,
		override_options => {
			'mysqld' => { 
				'max_connections' => '1024',
				'bind_address' => '0.0.0.0' 
			} 
		},
	}
	
	mysql::db { 'stelligent-demo':
		user		=> "stelligent-demo-user",
		password	=> "stelligent-demo-pass",
		host     => '%',
		grant    => ['SELECT', 'UPDATE']
	}
}

