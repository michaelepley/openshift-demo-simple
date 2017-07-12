#!/bin/bash

# Configuration

. ./config-demo-openshift-simple.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

echo -n "Verifying configuration ready..."
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_APPLICATION_NAME?}
echo "OK"

echo "Setup sample PHP + MySQL demo application: database backend"
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}  || { echo "FAILED: Could not login" && exit 1; }
echo "	--> Verify the openshift cluser is working normally"
oc status || { echo "FAILED: could not verify the openshift cluster is operational" && exit 1; }

echo "	--> Create a new application from the mysql-ephemeral template"
oc get dc/mysql || oc new-app mysql-ephemeral --name=mysql -l app=${OPENSHIFT_APPLICATION_NAME},part=backend --param=MYSQL_USER=myphp --param=MYSQL_PASSWORD=myphp --param=MYSQL_DATABASE=myphp || { echo "FAILED: Could find or create the application" && exit 1; }
echo "	--> and for convenience, lets group it with the original php service"
oc get svc/php && oc patch svc/php -p '{"metadata" : { "annotations" : { "service.alpha.openshift.io/dependencies" : "[ { \"name\" : \"mysql\" , \"kind\" : \"Service\"  } ]" } } }' || { echo "FAILED: Could not patch app=${OPENSHIFT_APPLICATION_NAME},part=backend" && exit 1; }

echo "	--> Verify the database automatically"
## OPENSHIFT_APPLICATION_MYSQL_PODS=`oc get pods -o jsonpath='{.items[*].metadata.name}' | grep -o '\bmysql[-a-zA-Z0-9]*\b'`
oc rsh dc/mysql /bin/sh -c 'echo -e "show tables;\nselect * from visitors;\n quit\n" | /opt/rh/rh-mysql57/root/usr/bin/mysql -h 127.0.0.1 -u myphp -P 3306 -D myphp -p myphp'
echo "	--> To verify database manually:" 
cat << EOF_SAMPLE_APPLICATION_DATABASE_MANUAL_VERIFICATION 
	oc rsh dc/mysql

	mysql -h 127.0.0.1 -u myphp -P 3306 -D myphp -p myphp
	show tables;
	select * from visitors;
	quit
	exit
EOF_SAMPLE_APPLICATION_DATABASE_MANUAL_VERIFICATION

#WANT, but regex matching does not appear supported at the moment:
#oc get pods -o jsonpath='{.items[?(@.metadata.name=~"^mysql")].metadata.name}'

echo "	--> Clean up just the database backend:  oc delete all -l part=backend && oc delete secret/mysql"
echo "Done"
