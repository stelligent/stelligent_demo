node /^stelligent-demo-jenkins.*/ {

	include jenkins
        jenkins::job { 'seed':
                config => template("/etc/puppet/templates/seed.xml.erb"),
        }
}
