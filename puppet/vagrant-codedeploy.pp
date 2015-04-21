node /^nando-demo-codedeploy.*/ {

	
	Exec { path => "/bin:/sbin:/usr/bin:/usr/sbin" }
	
	class { nginx: }
}
