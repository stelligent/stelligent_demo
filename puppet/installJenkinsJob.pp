node /.*internal$/ {
   	include jenkins
	jenkins::job { 'GetInstagramImages':
  		config => template("/etc/puppet/jobGetInstagramImages.xml.erb"),
	}
        jenkins::job { 'PublishCodeDeploy':
                config => template("/etc/puppet/jobPublishCodeDeploy.xml.erb"),
        }

}
