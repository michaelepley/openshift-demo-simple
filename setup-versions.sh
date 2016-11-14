#!/bin/bash

# Configuration

. ./config.sh

echo "Setup sample PHP + MySQL demo application: connect frontend and backend"
echo "	--> Log into openshift"
oc login ${OPENSHIFT_PRIMARY_MASTER}:${OPENSHIFT_PRIMARY_MASTER_PORT_HTTPS} --username=${OPENSHIFT_PRIMARY_USER} --password=${OPENSHIFT_PRIMARY_USER_PASSWORD} --insecure-skip-tls-verify=false || { echo "FAILED: could not login to openshift" && exit 1; }
echo "	--> Switch to project"
oc project ${OPENSHIFT_PRIMARY_PROJECT} || { echo "FAILED: Could not use indicated project" && exit 1; }

echo "	--> set a readiness probe for the frontend"
oc set probe dc/php --readiness --get-url=http://:8080/

echo "		--> NOTE: readiness probe now contaminates our frontend with extraneous results"
echo "		--> press enter to continue" && read
echo "	--> Roll back one version to remove the readiness probe"
oc rollback php --to-version=$(( `oc get dc/php --template={{.status.latestVersion}}` - 1 ))
echo "		--> press enter to continue" && read

echo "	--> Creating a new version of the application from a private branch of the app"
oc get dc/php-mepley || oc new-app php:5.6~https://github.com/michaelepley/phpmysqldemo.git#mepleys --name=php-mepley -l app=${OPENSHIFT_APPLICATION_NAME},part=frontend -e MYSQL_SERVICE_HOST=mysql.${OPENSHIFT_PRIMARY_PROJECT}.svc.cluster.local,MYSQL_SERVICE_PORT=3306,MYSQL_SERVICE_DATABASE=myphp,MYSQL_SERVICE_USERNAME=myphp,MYSQL_SERVICE_PASSWORD=myphp -o ${OPENSHIFT_OUTPUT_FORMAT_DEFAULT} > ose-app-${OPENSHIFT_APPLICATION_NAME}-php-mepley.${OPENSHIFT_OUTPUT_FORMAT_DEFAULT} || { echo "FAILED: Could find or create the application" && exit 1; }
oc create -f ose-app-${OPENSHIFT_APPLICATION_NAME}-php-mepley.${OPENSHIFT_OUTPUT_FORMAT_DEFAULT} 
oc patch dc/php-mepley -p '{"spec" : { "template" : { "spec" : { "containers" : [ { "name" : "php-mepley", "resources" : { "requests" : { "cpu" : "200m" } } } ] } } } }'
oc get route php-mepley || oc expose service php-mepley || { echo "FAILED: Could not verify route to application frontend" && exit 1; }
echo "	--> Waiting for pods to start"
for COUNT in {1..20} ; do echo -n "." && sleep 1s; done
echo "	--> open web page"
firefox php-mepley-${OPENSHIFT_PRIMARY_PROJECT}.${OPENSHIFT_PRIMARY_APPS}

echo "		--> press enter to continue" && read
echo "	--> create new endpoint"
oc get route visitors || oc expose service php-mepley --name visitors -l app=${OPENSHIFT_APPLICATION_NAME} --hostname="visitors.${OPENSHIFT_PRIMARY_APPS}"
firefox visitors.${OPENSHIFT_PRIMARY_APPS}
echo "		--> press enter to continue" && read
echo "	--> move old endpoint to new endpoint"
oc patch route/php -p '{"spec" : { "to" : { "name" : "php-mepley"} } }'
firefox php-${OPENSHIFT_PRIMARY_PROJECT}.${OPENSHIFT_PRIMARY_APPS}
echo "		--> press enter to continue" && read
echo "	--> create new a/b testing endpoint"
oc patch route/php -p '{"spec" : { "to" : { "name" : "php"} } }'
#--session-affinity=None 
oc get route visitorsab || oc expose service php-mepley --name visitorsab -l app=${OPENSHIFT_APPLICATION_NAME} --hostname="visitorsab.${OPENSHIFT_PRIMARY_APPS}"
oc set route-backends visitorsab php=50 php-mepley=50
for COUNT in {1..20} ; do curl -L -s http://visitorsab.${OPENSHIFT_PRIMARY_APPS} | grep -o "Database is available" || echo "No Color"; done
firefox visitorsab.${OPENSHIFT_PRIMARY_APPS}


echo "Done."
