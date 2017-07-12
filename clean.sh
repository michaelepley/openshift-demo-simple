#!/bin/bash	
# Configuration

. ./config-demo-openshift-simple.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

echo -n "Verifying configuration ready..."
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_APPLICATION_NAME?}
: ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP?}
echo "OK"

echo "Cleaning up sample PHP + MySQL demo application"
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP} || { echo "FAILED: Could not login" && exit 1; }
echo "	--> delete all openshift resources"
oc delete all -l app=${OPENSHIFT_APPLICATION_NAME}
echo "	--> delete project"
oc delete project ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}
echo "	--> delete all local artifacts"
echo "Done"
