#!/bin/bash

# Configuration

. ./config-demo-openshift-simple.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

echo -n "Verifying configuration ready..."
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_APPLICATION_NAME?}
: ${OPENSHIFT_OUTPUT_FORMAT?}
: ${OPENSHIFT_APPS?}
: ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP?}
echo "OK"
echo "Setup PHP Configuration_____________________________________"
echo "	OPENSHIFT_USER_REFERENCE             = ${OPENSHIFT_USER_REFERENCE}"
echo "	OPENSHIFT_APPLICATION_NAME           = ${OPENSHIFT_APPLICATION_NAME}"
echo "	OPENSHIFT_OUTPUT_FORMAT              = ${OPENSHIFT_OUTPUT_FORMAT}"
echo "	OPENSHIFT_APPS                       = ${OPENSHIFT_APPS}"
echo "	OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP   = ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}"
echo "____________________________________________________________"


echo "Setup sample PHP + MySQL demo application: php frontend"
echo "	--> Make sure we are logged in (to the right instance and as the right user)"
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP} || { echo "FAILED: Could not login" && exit 1; }
echo "	--> Verify the openshift cluster is working normally"

oc status -v || { echo "FAILED: could not verify the openshift cluster's operational status" && exit 1; }
echo "	--> Create a new application from the php:5.6 template and application git repo"
oc get dc/php || oc new-app php:5.6~https://github.com/michaelepley/phpmysqldemo.git --name=php -l app=${OPENSHIFT_APPLICATION_NAME},part=frontend -o ${OPENSHIFT_OUTPUT_FORMAT} > ose-app-${OPENSHIFT_APPLICATION_NAME}-php.${OPENSHIFT_OUTPUT_FORMAT} || { echo "FAILED: Could not find or create the app=${OPENSHIFT_APPLICATION_NAME},part=frontend " && exit 1; }
oc create -f ose-app-${OPENSHIFT_APPLICATION_NAME}-php.${OPENSHIFT_OUTPUT_FORMAT} || { echo "FAILED: Could not find or create app=${OPENSHIFT_APPLICATION_NAME},part=frontend" && exit 1; } 
oc patch dc/php -p '{"spec" : { "template" : { "spec" : { "containers" : [ { "name" : "php", "resources" : { "requests" : { "cpu" : "400m" } } } ] } } } }' || { echo "FAILED: Could not patch app=${OPENSHIFT_APPLICATION_NAME},part=frontend to set resource limits" && exit 1; }
oc patch dc/php -p '{"spec" : { "template" : { "spec" : { "containers" : [ { "name" : "php", "resources" : { "limits" : { "cpu" : "500m" } } } ] } } } }' || { echo "FAILED: Could not patch app=${OPENSHIFT_APPLICATION_NAME},part=frontend to set resource limits" && exit 1; }
echo "		--> Follow the build logs with " && echo "oc logs bc/php --follow" 

echo "	--> ensure the application is routable"
oc get route php || oc expose service php || { echo "FAILED: Could not verify route to app=${OPENSHIFT_APPLICATION_NAME},part=frontend" && exit 1; }

echo "	--> Waiting for the ${OPENSHIFT_APPLICATION_FRONTEND_NAME} application to start....press any key to proceed"
while ! oc get pods | grep php | grep Running ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""

echo "	--> open web page"
firefox php-${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}.${OPENSHIFT_APPS}

echo "Done."
