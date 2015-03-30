node /.*internal$/ {
   	include jenkins
	jenkins::job { 'nando-automation-demo':
  		config => template("/etc/puppet/nando-automation-demo.xml.erb"),
	}
}
