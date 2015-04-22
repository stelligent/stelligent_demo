node /^nando-demo-mysql.*/ {
  		
	Exec { path => "/bin:/sbin:/usr/bin:/usr/sbin" }
	
	class { '::mysql::server':
  		#root_password    => 'mysql-root-password',
		remove_default_accounts => true,
  		override_options => { 'mysqld' => { 'max_connections' => '1024' } },
	}
	
	mysql::db { 'nando-demo':
		user		=> "nando-demo-user",
		password	=> "nando-demo-pass",
  		host     => '%',
  		grant    => ['SELECT', 'UPDATE'],
	}
}

