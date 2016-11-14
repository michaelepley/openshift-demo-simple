#!/bin/bash

# Configuration

. ./config.sh

echo "Setup sample PHP + MySQL demo application: connect frontend and backend"
echo "	--> Log into openshift"
oc login ${OPENSHIFT_PRIMARY_MASTER}:${OPENSHIFT_PRIMARY_MASTER_PORT_HTTPS} --username=${OPENSHIFT_PRIMARY_USER} --password=${OPENSHIFT_PRIMARY_USER_PASSWORD} --insecure-skip-tls-verify=false || { echo "FAILED: could not login to openshift" && exit 1; }
echo "	--> Switch to project"
oc project ${OPENSHIFT_PRIMARY_PROJECT} || { echo "FAILED: Could not use indicated project" && exit 1; }

echo "	--> Adding database connection parameters to frontend"
oc env dc/php MYSQL_SERVICE_HOST=mysql.${OPENSHIFT_PRIMARY_PROJECT}.svc.cluster.local MYSQL_SERVICE_PORT=3306 MYSQL_SERVICE_DATABASE=myphp MYSQL_SERVICE_USERNAME=myphp MYSQL_SERVICE_PASSWORD=myphp

echo "	--> Adding database connection parameters to backend"
oc env dc/mysql MYSQL_USER=myphp MYSQL_PASSWORD=myphp MYSQL_DATABASE=myphp

echo "	--> Waiting for pods to restart"
for COUNT in {1..20} ; do echo -n "." && sleep 1s; done

echo "	--> Verify the frontend is connected to the backend"
curl -L -s http://php-${OPENSHIFT_APPLICATION_NAME}.${OPENSHIFT_PRIMARY_APPS} | grep -o "Database is available"
echo "Done."