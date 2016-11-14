#!/bin/bash

# Configuration

. ./config.sh

echo "Setup sample PHP + MySQL demo application: database backend"
echo "	--> Log into openshift"
oc login ${OPENSHIFT_PRIMARY_MASTER}:${OPENSHIFT_PRIMARY_MASTER_PORT_HTTPS} --username=${OPENSHIFT_PRIMARY_USER} --password=${OPENSHIFT_PRIMARY_USER_PASSWORD} --insecure-skip-tls-verify=false || { echo "FAILED: could not login to openshift" && exit 1; }
echo "	--> Create a new project"
oc project ${OPENSHIFT_PRIMARY_PROJECT} || oc new-project ${OPENSHIFT_PRIMARY_PROJECT} || { echo "FAILED: Could not use indicated project" && exit 1; }
echo "	--> Create a new application from the mysql-ephemeral template"
oc get dc/mysql || oc new-app mysql-ephemeral --name=mysql -l app=${OPENSHIFT_APPLICATION_NAME},part=backend -p MYSQL_USER=myphp,MYSQL_PASSWORD=myphp,MYSQL_DATABASE=myphp || { echo "FAILED: Could find or create the application" && exit 1; }
echo "	--> Verify the application is working normally"
oc status || { echo "FAILED" && exit 1; }
echo "	--> Verify database manually:" 
echo << EOF_SAMPLE_APPLICATION_DATABASE_MANUAL_VERIFICATION 
echo "	oc get pods
	oc rsh mysql-1-<pod>

	mysql -h 127.0.0.1 -u myphp -P 3306 -p myphp myphp
	show tables;
	select * from visitors;
	quit
	exit
EOF_SAMPLE_APPLICATION_DATABASE_MANUAL_VERIFICATION
echo "Done"
