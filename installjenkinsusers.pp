node /.*internal$/ {
   	include jenkins
  	jenkins::user { 'nando':
    		email    => 'fernando.pando@stelligent.com',
    		password => 'changeme123',
  	}
}

