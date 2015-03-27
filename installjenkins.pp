node /.*internal$/ {
   	include jenkins
	jenkins::plugin {
  		"git" : ;
	}
}
