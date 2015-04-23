node /.*internal$/ {
   	include jenkins
        jenkins::plugin { 'python': }
	jenkins::plugin { 'credentials': }
	jenkins::plugin { 'github': }
	jenkins::plugin { 'ssh-credentials': }
	jenkins::plugin { 'github-api': }
	jenkins::plugin { 'scm-api': }
	jenkins::plugin { 'git-client': }
	jenkins::plugin { 'git': }
	jenkins::plugin { 'parameterized-trigger': }
	jenkins::plugin { 'maven': }
	jenkins::plugin { 'promoted-builds': }
	jenkins::plugin { 'job-dsl': }
}

