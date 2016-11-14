#!/bin/bash

# Configuration

. ./config.sh

echo "Setup sample PHP + MySQL demo application: php frontend"
echo "	--> Log into openshift"
oc login ${OPENSHIFT_PRIMARY_MASTER}:${OPENSHIFT_PRIMARY_MASTER_PORT_HTTPS} --username=${OPENSHIFT_PRIMARY_USER} --password=${OPENSHIFT_PRIMARY_USER_PASSWORD} --insecure-skip-tls-verify=false || { echo "FAILED: could not login to openshift" && exit 1; }
echo "	--> Create a new project"
oc project ${OPENSHIFT_PRIMARY_PROJECT} || oc new-project ${OPENSHIFT_PRIMARY_PROJECT} || { echo "FAILED: Could not use indicated project" && exit 1; }
echo "	--> Create a new application from the php:5.6 template and application git repo"
oc get dc/php || oc new-app php:5.6~https://github.com/michaelepley/phpmysqldemo.git --name=php -l app=${OPENSHIFT_APPLICATION_NAME},part=frontend -o ${OPENSHIFT_OUTPUT_FORMAT_DEFAULT} > ose-app-${OPENSHIFT_APPLICATION_NAME}-php.${OPENSHIFT_OUTPUT_FORMAT_DEFAULT} || { echo "FAILED: Could find or create the application" && exit 1; }
oc create -f ose-app-${OPENSHIFT_APPLICATION_NAME}-php.${OPENSHIFT_OUTPUT_FORMAT_DEFAULT} 
oc patch dc/php -p '{"spec" : { "template" : { "spec" : { "containers" : [ { "name" : "php", "resources" : { "requests" : { "cpu" : "400m" } } } ] } } } }'
oc patch dc/php -p '{"spec" : { "template" : { "spec" : { "containers" : [ { "name" : "php", "resources" : { "limits" : { "cpu" : "500m" } } } ] } } } }'
echo "		--> Follow the build logs with " && echo "oc logs bc/php --follow" 
echo "	--> Verify the application is working normally"
oc status -v || { echo "FAILED" && exit 1; }

echo "	--> ensure the application is routable"
oc get route php || oc expose service php || { echo "FAILED: Could not verify route to application frontend" && exit 1; }

echo "	--> Waiting for pods to start"
for COUNT in {1..20} ; do echo -n "." && sleep 1s; done

echo "	--> open web page"
firefox php-${OPENSHIFT_PRIMARY_PROJECT}.${OPENSHIFT_PRIMARY_APPS}

echo "Done"
