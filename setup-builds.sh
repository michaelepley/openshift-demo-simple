#!/bin/bash

# Configuration

. ./config-demo-openshift-simple.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

echo -n "Verifying configuration ready..."
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_APPS?}
: ${OPENSHIFT_APPLICATION_NAME?}
: ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP?}
echo "OK"
echo "Setup sample PHP + MySQL demo application: Setup complex application build environment"
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP} || { echo "FAILED: Could not login" && exit 1; }
echo "	--> Make sure that jenkins is set up first"
echo "		--> OCP build pipelines are managed via a jenkins server deployed in the project"
# oc get dc/jenkins || oc process openshift//jenkins-ephemeral -l app=${OPENSHIFT_APPLICATION_NAME},part=cicd JENKINS_PASSWORD=password | oc create -f - || { echo "FAILED: Could not create Jenkins CICD server" && exit 1; }
oc get dc/jenkins || oc process openshift//jenkins-ephemeral -l app=${OPENSHIFT_APPLICATION_NAME},part=cicd | oc create -f - || { echo "FAILED: Could not create Jenkins CICD server" && exit 1; }
echo "	--> Waiting for jenkins pods to start"
sleep 2s
for COUNT in {1..45} ; do curl -s "http://jenkins-${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}.${OPENSHIFT_APPS}/login?from=%2F" && break; echo -n "." && sleep 1s; done; echo ""
echo "		--> press enter to continue" && read
echo "	--> Creating Jenkins build pipeline for the php frontend"
oc get bc/phppipeline || echo '{ "apiVersion": "v1", "kind": "BuildConfig", "metadata": { "name": "phppipeline", "labels": { "app": "php", "part": "frontend" }, "annotations": { "pipeline.alpha.openshift.io/uses": "[{\"name\": \"php\", \"namespace\": \"\", \"kind\": \"DeploymentConfig\"}]" } }, "spec": { "runPolicy": "Serial", "strategy": { "type": "Source", "jenkinsPipelineStrategy": { "jenkinsfile": "node('\''maven'\'') {\n  stage '\''build'\''\n  openshiftBuild(buildConfig: '\''php'\'', showBuildLogs: '\''true'\'')\nstage '\''deploy'\''\n  openshiftDeploy(deploymentConfig: '\''php'\'')\n  openshiftScale(deploymentConfig: '\''php'\'',replicaCount: '\''2'\'')\n}" } }, "output": {}, "resources": {} } }' | oc create -f - || { echo "FAILED: could not find or create build pipeline definition" && exit 1; }

echo "		--> press enter to continue" && read

echo "	--> Trigger a build using the pipeline"
oc start-build bc/phppipeline || { echo "FAILED: Could not start build pipeline" && exit 1; }
echo "		--> press enter to continue" && read

echo "	--> TODO: Add a github webhook to trigger the build"



echo "	--> open web browser"
echo "		--> the php build pipelines status should be shown; at least one build should be shown in it"
firefox https://jenkins-${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}.${OPENSHIFT_APPS}/
echo "		--> on php build pipelines status page, select the most recent and this should show a detailed log of its activities, including the delegation to the openshift builder, the deployment, and the scaling of the application"
firefox https://jenkins-${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}.${OPENSHIFT_APPS}/job/phppipeline/

echo "Done"

