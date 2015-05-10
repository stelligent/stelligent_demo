node /.*internal$/ {
   	include jenkins
	jenkins::job { 'InstagramImageGet':
  		config => template("/etc/puppet/manifests/jobInstagramImageGet.xml.erb"),
	}
	jenkins::job { 'InstagramImageTest':
  		config => template("/etc/puppet/manifests/jobInstagramImageTest.xml.erb"),
	}
	jenkins::job { 'InstagramImageSave':
  		config => template("/etc/puppet/manifests/jobInstagramImageSave.xml.erb"),
	}
        jenkins::job { 'seed':
                config => template("/etc/puppet/manifests/seed.xml.erb"),
        }
}
