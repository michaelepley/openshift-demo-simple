#!/bin/bash	
# Configuration

. ./config.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

echo "Cleaning up sample PHP + MySQL demo application"
. ./setup-login.sh -r OPENSHIFT_USER_RHSADEMO_MEPLEY || { echo "FAILED: Could not login" && exit 1; }
echo "	--> delete all openshift resources"
oc delete all -l app=${OPENSHIFT_APPLICATION_NAME}
echo "	--> delete project"
oc delete project ${OPENSHIFT_PRIMARY_PROJECT_MYSQLPHP_DEFAULT}
echo "	--> delete all local artifacts"
echo "Done"
