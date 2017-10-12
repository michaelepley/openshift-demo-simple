#!/bin/bash

# Configuration

. ./config-demo-openshift-simple.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY=registry.access.redhat.com
CONTENT_SOURCE_DOCKER_IMAGES_FEDORA_REGISTRY=registry.fedoraproject.org


echo -n "Verifying configuration ready..."
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_APPLICATION_NAME?}
: ${OPENSHIFT_OUTPUT_FORMAT?}
: ${OPENSHIFT_APPS?}
: ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP?}
echo "OK"
echo "Setup DEMO Configuration_____________________________________"
echo "	OPENSHIFT_USER_REFERENCE             = ${OPENSHIFT_USER_REFERENCE}"
echo "	OPENSHIFT_APPLICATION_NAME           = ${OPENSHIFT_APPLICATION_NAME}"
echo "	OPENSHIFT_OUTPUT_FORMAT              = ${OPENSHIFT_OUTPUT_FORMAT}"
echo "	OPENSHIFT_APPS                       = ${OPENSHIFT_APPS}"
echo "	OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP   = ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}"
echo "	CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY = ${CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY}"
echo "____________________________________________________________"


echo "Setup demo runner in openshift"
echo "	--> Make sure we are logged in (to the right instance and as the right user)"
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP} || { echo "FAILED: Could not login" && exit 1; }
echo "	--> Verify the openshift cluster is working normally"

echo " --> install prerequisite images"
oc get is rhel -o jsonpath='{.spec.tags[*].name}' | grep 7 || oc get is rhel -n openshift -o jsonpath='{.spec.tags[*].name}' | grep 7 || oc import-image rhel:7 --from=${CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY}/rhel7/rhel:latest --confirm
oc get is fedora -o jsonpath='{.spec.tags[*].name}' | grep 26 || oc get is fedora -n openshift -o jsonpath='{.spec.tags[*].name}' | grep 26 || oc import-image fedora:26 --from=${CONTENT_SOURCE_DOCKER_IMAGES_FEDORA_REGISTRY}/fedora:26 --confirm || { echo "FAILED: could not find or import required fedora image" && exit 1 ; }
oc get is redhat-openjdk18-openshift -o jsonpath='{.spec.tags[*].name}' || oc get is redhat-openjdk18-openshift -n openshift -o jsonpath='{.spec.tags[*].name}' || oc import-image redhat-openjdk18-openshift --from=${CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY}/redhat-openjdk-18/openjdk18-openshift:latest --confirm

APPLICATION_DEMO_RUNNER_PLATFORM=FEDORA

APPLICATION_DEMO_RUNNER_DOCKER_BASE_IMAGE_RHEL=${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}/rhel:7
APPLICATION_DEMO_RUNNER_DOCKER_BASE_IMAGE_FEDORA=${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}/fedora:26

APPLICATION_DEMO_RUNNER_DOCKER_DOCKERFILE_RHEL=$'FROM rhel\nRUN yum clean all && yum-config-manager --enable rhel-7-server-rpms rhel-7-server-ose-3.6-rpms && yum repolist && yum install -y openssl iputil && {  yum install -y  origin-clients ||  yum install -y --enablerepo=rhel-7-server-ose-3.6-rpms atomic-openshift-clients ; }\nADD . /demo/\nRUN chmod -R g+w /demo'
#### including additional repos: FROM rhel\nRUN yum clean all && yum-config-manager --disable \* && yum-config-manager --enable rhel-7-server-rpms rhel-server-rhscl-7-rpms rhel-7-server-extras-rpms rhel-7-server-supplementary-rpms rhel-7-server-optional-rpms && yum install -y openssl ping && {  yum install -y  origin-clients ||  yum install -y atomic-openshift-clients } \nADD . /demo/
APPLICATION_DEMO_RUNNER_DOCKER_DOCKERFILE_FEDORA=$'FROM fedora:26\nRUN dnf clean all && dnf install -y openssl iputils origin-clients\nADD . /demo/\nRUN chmod -R g+w /demo'
APPLICATION_DEMO_RUNNER_DOCKER_BASE=${APPLICATION_DEMO_RUNNER_DOCKER_BASE_IMAGE_FEDORA}
APPLICATION_DEMO_RUNNER_DOCKERFILE=${APPLICATION_DEMO_RUNNER_DOCKER_DOCKERFILE_FEDORA}

echo "	--> Creating new build for demo runner"
oc new-build --name=demo-runner --image-stream=${APPLICATION_DEMO_RUNNER_DOCKER_BASE} --code=https://github.com/michaelepley/openshift-demo-simple.git --strategy=docker --dockerfile="${APPLICATION_DEMO_RUNNER_DOCKERFILE}" -l app=demo-runner,name=demo-runner || { echo "FAILED: could not create demo runner" && exit 1; } 
echo "	--> waiting for build to succeed, press any key to cancel"
while [ ! "`oc get build -l buildconfig=demo-runner --template='{{range .items}}{{if (eq .metadata.name "demo-runner-1")}}{{.status.phase}}{{end}}{{end}}'`" == "Complete" ] ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""
oc new-app --name=demo-runner --image-stream=demo-runner -e USER=${USER}-e OPENSHIFT_RHSADEMO_USER_PASSWORD_DEFAULT_CIPHERTEXT="${OPENSHIFT_RHSADEMO_USER_PASSWORD_DEFAULT_CIPHERTEXT}" -e SCRIPT_ENCRYPTION_KEY="${SCRIPT_ENCRYPTION_KEY}" -e GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT="${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT}"

oc patch dc/demo-runner -p '{"spec": {"template": {"spec": {"containers":[{"name":"demo-runner", "command": ["/bin/sleep", "infinity"]}]}}}}'


echo "Done."
