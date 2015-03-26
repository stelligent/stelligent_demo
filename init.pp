node /.*internal$/ {
   	include jenkins
	
	jenkins::plugin {
  		"git" : ;
	}

	jenkins::job { 'nando-automation-demo':
  		config => template("/etc/puppet/nando-automation-demo.xml.erb"),
	}
}
