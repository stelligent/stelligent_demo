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
        jenkins::job { 'DeployStage':
                config => template("/etc/puppet/manifests/jobDeployStage.xml.erb"),
        }
        jenkins::job { 'DeployStageTests':
                config => template("/etc/puppet/manifests/jobDeployStageTests.xml.erb"),
        }
        jenkins::job { 'DeployProduction':
                config => template("/etc/puppet/manifests/jobDeployProduction.xml.erb"),
        }

}
