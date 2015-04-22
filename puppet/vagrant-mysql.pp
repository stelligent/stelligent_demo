node /^nando-demo-mysql.*/ {
  		
	$u = file("/vagrant/mysql/NandoDemoDBUser")
	$p = file("/vagrant/mysql/NandoDemoDBPass")

	Exec { path => "/bin:/sbin:/usr/bin:/usr/sbin" }
	
	class { '::mysql::server':
  		root_password    => 'mysql-root-password',
		remove_default_accounts => true,
  		override_options => { 'mysqld' => { 'max_connections' => '1024' } },
	}
	
	mysql::db { 'nando-demo':
  		user     => $u,
  		password => $p,
  		host     => '*',
  		grant    => ['SELECT', 'UPDATE'],
	}
}

