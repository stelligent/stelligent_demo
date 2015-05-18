node /.*/ {
   	include jenkins

	class { jenkins::security:
		security_model => 'full_control',
	}

}

