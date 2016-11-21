#!/bin/bash	
# Configuration

. ./config.sh

echo "Cleaning up sample PHP + MySQL demo application"
. ./setup-login.sh
echo "	--> delete all openshift resources"
oc delete all -l app=${OPENSHIFT_APPLICATION_NAME}
echo "	--> delete project"
#oc delete project ${OPENSHIFT_PRIMARY_PROJECT}
echo "	--> delete all local artifacts"
echo "Done"
