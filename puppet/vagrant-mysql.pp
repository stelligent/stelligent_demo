node '^nando-demo-mysql.*/ {

	
	Exec { path => "/bin:/sbin:/usr/bin:/usr/sbin" }
	
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
