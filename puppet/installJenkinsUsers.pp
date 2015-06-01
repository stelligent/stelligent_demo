node /.*internal$/ {
   	include jenkins

  	jenkins::user { 'stelligentdemo':
    		email    => 'fernando.pando@stelligent.com',
    		password => 'changeme123',
  	}
}

