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
        jenkins::job { 'CodeDeployStage':
                config => template("/etc/puppet/manifests/jobCodeDeployStage.xml.erb"),
        }
        jenkins::job { 'CodeDeployStageTests':
                config => template("/etc/puppet/manifests/jobCodeDeployStageTests.xml.erb"),
        }
        jenkins::job { 'CodeDeployProduction':
                config => template("/etc/puppet/manifests/jobCodeDeployProduction.xml.erb"),
        }
        jenkins::job { 'DockerStage':
                config => template("/etc/puppet/manifests/jobDockerStage.xml.erb"),
        }
        jenkins::job { 'DockerStageTests':
                config => template("/etc/puppet/manifests/jobDockerStageTests.xml.erb"),
        }
        jenkins::job { 'DockerProduction':
                config => template("/etc/puppet/manifests/jobDockerProduction.xml.erb"),
        }
        jenkins::job { 'seed':
                config => template("/etc/puppet/manifests/seed.xml.erb"),
        }
}
