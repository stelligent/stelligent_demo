node /.*/ {
   	include jenkins
        jenkins::job { 'seed':
                config => template("/etc/puppet/templates/seed.xml.erb"),
        }
}
