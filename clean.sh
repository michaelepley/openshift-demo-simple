#!/bin/bash	
# Configuration

. ./config.sh

echo "	--> Log into openshift"
oc login ${OPENSHIFT_PRIMARY_MASTER}:${OPENSHIFT_PRIMARY_MASTER_PORT_HTTPS} --username=${OPENSHIFT_PRIMARY_USER} --password=${OPENSHIFT_PRIMARY_USER_PASSWORD} --insecure-skip-tls-verify=false
echo "	--> Switch to project"
oc project ${OPENSHIFT_PRIMARY_PROJECT}
echo "	--> delete all openshift resources"
oc delete all -l app=${OPENSHIFT_APPLICATION_NAME}
echo "	--> delete project"
#oc delete project ${OPENSHIFT_PRIMARY_PROJECT}
echo "	--> delete all local artifacts"
echo "Done"
