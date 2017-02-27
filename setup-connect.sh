#!/bin/bash

# Configuration

. ./config.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

echo "Setup sample PHP + MySQL demo application: connect frontend and backend"
. ./setup-login.sh -r OPENSHIFT_USER_RHSADEMO_MEPLEY || { echo "FAILED: Could not login" && exit 1; }
echo "	--> Adding database connection parameters to frontend"
oc env dc/php MYSQL_SERVICE_HOST=mysql.${OPENSHIFT_PRIMARY_PROJECT_MYSQLPHP_DEFAULT}.svc.cluster.local MYSQL_SERVICE_PORT=3306 MYSQL_SERVICE_DATABASE=myphp MYSQL_SERVICE_USERNAME=myphp MYSQL_SERVICE_PASSWORD=myphp
echo "	--> Adding database connection parameters to backend"
oc env dc/mysql MYSQL_USER=myphp MYSQL_PASSWORD=myphp MYSQL_DATABASE=myphp
echo "	--> Waiting for pods to restart"
sleep 5s;
for COUNT in {1..20} ; do curl -L -s 'http://php-'${OPENSHIFT_PRIMARY_PROJECT_MYSQLPHP_DEFAULT}'.'${OPENSHIFT_PRIMARY_APPS} | grep -o "Database is available" && break; echo -n "." && sleep 1s; done
echo "	--> Verify the frontend is connected to the backend"
curl -L -s 'http://php-'${OPENSHIFT_PRIMARY_PROJECT_MYSQLPHP_DEFAULT}'.'${OPENSHIFT_PRIMARY_APPS} | grep -o "Database is available" || echo "ERROR: Could not verify the php frontend is connected to the mysql backend"
echo "Done."