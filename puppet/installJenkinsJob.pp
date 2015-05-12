node /.*internal$/ {
   	include jenkins
        jenkins::job { 'seed':
                config => template("/etc/puppet/manifests/seed.xml.erb"),
        }
}
