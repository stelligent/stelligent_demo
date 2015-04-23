node /.*internal$/ {
   	include jenkins
	jenkins::job { 'InstagramImageGet':
  		config => template("/etc/puppet/jobInstagramImageGet.xml.erb"),
	}
	jenkins::job { 'InstagramImageTest':
  		config => template("/etc/puppet/jobInstagramImageTest.xml.erb"),
	}
	jenkins::job { 'InstagramImageSave':
  		config => template("/etc/puppet/jobInstagramImageSave.xml.erb"),
	}
        jenkins::job { 'DeployStage':
                config => template("/etc/puppet/jobDeployStage.xml.erb"),
        }
        jenkins::job { 'DeployStageTests':
                config => template("/etc/puppet/jobDeployStageTests.xml.erb"),
        }
        jenkins::job { 'DeployProduction':
                config => template("/etc/puppet/jobDeployProduction.xml.erb"),
        }

}
