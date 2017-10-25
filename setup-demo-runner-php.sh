#!/bin/bash

# Configuration

. ./config-demo-openshift-simple.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

APPLICATION_NAME=demo-runner-php
#APPLICATION_REPOSITORY_GITHUB=https://github.com/michaelepley/phpmysqldemo.git
APPLICATION_REPOSITORY_GITHUB=https://github.com/michaelepley/openshift-demo-simple.git

CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY=registry.access.redhat.com
CONTENT_SOURCE_DOCKER_IMAGES_FEDORA_REGISTRY=registry.fedoraproject.org


echo -n "Verifying configuration ready..."
: ${APPLICATION_NAME?"missing configuration for APPLICATION_NAME"}
: ${APPLICATION_REPOSITORY_GITHUB?"missing configuration for APPLICATION_REPOSITORY_GITHUB"}
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_OUTPUT_FORMAT?"missing configuration for OPENSHIFT_OUTPUT_FORMAT"}
: ${OPENSHIFT_APPS?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP?}
# : ${CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY?"missing configuration for CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY"}
echo "OK"

echo "Setup DEMO Configuration_____________________________________"
echo "	OPENSHIFT_USER_REFERENCE             = ${OPENSHIFT_USER_REFERENCE}"
echo "	OPENSHIFT_APPLICATION_NAME           = ${OPENSHIFT_APPLICATION_NAME}"
echo "	OPENSHIFT_OUTPUT_FORMAT              = ${OPENSHIFT_OUTPUT_FORMAT}"
echo "	OPENSHIFT_APPS                       = ${OPENSHIFT_APPS}"
echo "	OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP   = ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}"
echo "	CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY = ${CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY}"
echo "____________________________________________________________"


echo "Setup PHP based demo runner in openshift"
echo "	--> Make sure we are logged in (to the right instance and as the right user)"
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP} || { echo "FAILED: Could not login" && exit 1; }
echo "	--> Verify the openshift cluster is working normally"

APPLICATION_DEMO_RUNNER_PLATFORM=FEDORA

APPLICATION_DEMO_RUNNER_DOCKER_BASE_IMAGE_RHEL=${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}/rhel:7
APPLICATION_DEMO_RUNNER_DOCKER_BASE_IMAGE_FEDORA=${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}/fedora:26

APPLICATION_DEMO_RUNNER_DOCKER_DOCKERFILE_RHEL=$'FROM rhel\nRUN yum clean all && yum-config-manager --enable rhel-7-server-rpms rhel-7-server-ose-3.6-rpms && yum repolist && yum install -y openssl iputils && {  yum install -y  origin-clients ||  yum install -y --enablerepo=rhel-7-server-ose-3.6-rpms atomic-openshift-clients ; }\nADD . /demo/\nRUN chmod -R g+w /demo\nENV KUBECONFIG=/demo/.kubeconfig'
#### including additional repos: FROM rhel\nRUN yum clean all && yum-config-manager --disable \* && yum-config-manager --enable rhel-7-server-rpms rhel-server-rhscl-7-rpms rhel-7-server-extras-rpms rhel-7-server-supplementary-rpms rhel-7-server-optional-rpms && yum install -y openssl ping && {  yum install -y  origin-clients ||  yum install -y atomic-openshift-clients } \nADD . /demo/
APPLICATION_DEMO_RUNNER_DOCKER_DOCKERFILE_FEDORA=$'FROM fedora:26\nRUN dnf clean all && dnf install -y openssl iputils origin-clients\nADD . /demo/\nRUN chmod -R g+w /demo\nENV KUBECONFIG=/demo/.kubeconfig'
APPLICATION_DEMO_RUNNER_DOCKER_BASE=${APPLICATION_DEMO_RUNNER_DOCKER_BASE_IMAGE_FEDORA}
APPLICATION_DEMO_RUNNER_DOCKERFILE=${APPLICATION_DEMO_RUNNER_DOCKER_DOCKERFILE_RHEL}
APPLICATION_DEMO_RUNNER_PHP_DOCKER_BASE=php:latest
APPLICATION_DEMO_RUNNER_DOCKER_BASE=${APPLICATION_DEMO_RUNNER_PHP_DOCKER_BASE}

echo "	--> Creating new build for demo runner"
oc get bc/${APPLICATION_NAME}-layer0 || oc new-build --name=${APPLICATION_NAME}-layer0 --image-stream=${APPLICATION_DEMO_RUNNER_DOCKER_BASE} --code=${APPLICATION_REPOSITORY_GITHUB} --strategy=docker --dockerfile="${APPLICATION_DEMO_RUNNER_DOCKERFILE}" -l app=${APPLICATION_NAME},name=${APPLICATION_NAME} || { echo "FAILED: could not create demo runner" && exit 1; } 

echo "	--> waiting for build to succeed, press any key to cancel"
while [ ! "`oc get build -l buildconfig=${APPLICATION_NAME}-layer0 --template='{{range .items}}{{if (eq .metadata.name "'${APPLICATION_NAME}-layer0'-1")}}{{.status.phase}}{{end}}{{end}}'`" == "Complete" ] ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""


echo "	--> Create a new application from the php:latest template pointed at myself"
oc get dc/${APPLICATION_NAME} || oc new-app --name=${APPLICATION_NAME} ${APPLICATION_NAME}-layer0~${APPLICATION_REPOSITORY_GITHUB} -l app=${APPLICATION_NAME},part=runner -e USER=${USER} -e OPENSHIFT_RHSADEMO_USER_PASSWORD_DEFAULT_CIPHERTEXT="${OPENSHIFT_RHSADEMO_USER_PASSWORD_DEFAULT_CIPHERTEXT}" -e SCRIPT_ENCRYPTION_KEY="${SCRIPT_ENCRYPTION_KEY}" -e GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT="${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT}" || { echo "FAILED: Could not find or create the app=${APPLICATION_NAME},part=runner " && exit 1; }


echo "Done."
