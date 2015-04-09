node /.*internal$/ {
	class { jenkins:
		lts => true,
	}
}
