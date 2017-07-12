#!/bin/bash

# Configuration

. ./config-demo-openshift-simple.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

echo -n "Verifying configuration ready..."
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_APPS?}
: ${OPENSHIFT_APPLICATION_NAME?}
: ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP?}
echo "OK"

echo "Setup sample PHP + MySQL demo application: connect frontend and backend"
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP} || { echo "FAILED: Could not login" && exit 1; }
echo "	--> Adding database connection parameters to frontend"
oc env dc/php MYSQL_SERVICE_HOST=mysql.${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}.svc.cluster.local MYSQL_SERVICE_PORT=3306 MYSQL_SERVICE_DATABASE=myphp MYSQL_SERVICE_USERNAME=myphp MYSQL_SERVICE_PASSWORD=myphp
echo "	--> Adding database connection parameters to backend"
oc env dc/mysql MYSQL_USER=myphp MYSQL_PASSWORD=myphp MYSQL_DATABASE=myphp
echo "	--> Waiting for pods to restart"
sleep 5s;
echo "	--> Waiting for application to detect database"
while ! curl -L -s 'http://php-'${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}'.'${OPENSHIFT_APPS} | grep -o "Database is available" ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""

echo "	--> Verify the frontend is connected to the backend"
curl -L -s 'http://php-'${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}'.'${OPENSHIFT_APPS} | grep -o "Database is available" || echo "ERROR: Could not verify the php frontend is connected to the mysql backend"
echo "Done."