freeStyleJob ('dumpXML') {
	steps {
		shell('for job in $(ls /var/lib/jenkins/jobs/); do echo $job; cat /var/lib/jenkins/jobs/$job/config.xml; echo ; done')
	}
}

freeStyleJob ('CodeDeployStage') {
	steps {
		shell('commitID=$(git rev-parse --verify HEAD && deployID=$(aws deploy create-deployment --application-name nando-demo --region us-east-1 --github-location commitId=$commitID,repository=stelligent/nando_automation_demo --deployment-group-name nando-demo) && aws deploy get-deployment --deployment-id $deployID  --query "deploymentInfo.status" --output text')
	}
}

freeStyleJob ('CodeDeployProduction') {
}

freeStyleJob ('DockerProduction') {
}

freeStyleJob ('CodeDeployStageTests') {
}

freeStyleJob ('DockerStageTests') {
}

freeStyleJob ('DockerStage') {
}
