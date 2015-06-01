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
	jenkins::plugin { 'promoted-builds': }
	jenkins::plugin { 'job-dsl': }
	jenkins::plugin { 'build-flow-plugin': }
  jenkins::plugin { 'token-macro': }
  jenkins::plugin { 'jquery': }
  jenkins::plugin { 'delivery-pipeline-plugin': }
  jenkins::plugin { 'build-pipeline-plugin': }
}

