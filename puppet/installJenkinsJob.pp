node /.*internal$/ {
   	include jenkins
	jenkins::job { 'InstagramImagesGet':
  		config => template("/etc/puppet/jobInstagramImagesGet.xml.erb"),
	}
	jenkins::job { 'InstagramImagesTest':
  		config => template("/etc/puppet/jobInstagramImagesTest.xml.erb"),
	}
	jenkins::job { 'InstagramImagesSave':
  		config => template("/etc/puppet/jobInstagramImagesSave.xml.erb"),
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
