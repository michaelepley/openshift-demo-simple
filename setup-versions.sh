#!/bin/bash

# Configuration

. ./config-demo-openshift-simple.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

APPLICATION_SERVICE_V1_NAME=blue
APPLICATION_SERVICE_V2_NAME=green

echo -n "Verifying configuration ready..."
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_APPS?}
: ${OPENSHIFT_APPLICATION_NAME?}
: ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP?}
: ${APPLICATION_SERVICE_V1_NAME?}
: ${APPLICATION_SERVICE_V2_NAME?}
echo "OK"

echo "Setup sample PHP + MySQL demo application: add some additional versions"
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP} || { echo "FAILED: Could not login" && exit 1; }
echo "	--> Opening application endpoint at php-${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}.${OPENSHIFT_APPS}"
firefox "php-${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}.${OPENSHIFT_APPS}/?refresh=2"
echo "	--> set a readiness probe for the frontend"
oc set probe dc/php --readiness --period-seconds=5s --get-url=http://:8080/
echo "		--> NOTE: readiness probe now contaminates our frontend with extraneous results"
echo "		--> press enter to continue" && read
echo "	--> Roll back one version to remove the readiness probe"
oc rollback php --to-version=$(( `oc get dc/php --template={{.status.latestVersion}}` - 1 ))
# oc deploy php --enable-triggers
echo "		--> press enter to continue" && read
echo "	--> Re enable deployment triggers to prevent being locked to rolled back version"
oc deploy php --enable-triggers
oc set triggers dc/php --auto


echo "	--> Creating a new version of the application from a private branch of the app"
oc get dc/${APPLICATION_SERVICE_V1_NAME} || oc new-app php:5.6~https://github.com/michaelepley/phpmysqldemo.git#${APPLICATION_SERVICE_V1_NAME} --name=${APPLICATION_SERVICE_V1_NAME} -l app=${OPENSHIFT_APPLICATION_NAME}-${APPLICATION_SERVICE_V1_NAME},part=frontend -e MYSQL_SERVICE_HOST=mysql-${APPLICATION_SERVICE_V1_NAME}.${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}.svc.cluster.local -e MYSQL_SERVICE_PORT=3306 -e MYSQL_SERVICE_DATABASE=myphp -e MYSQL_SERVICE_USERNAME=myphp -e MYSQL_SERVICE_PASSWORD=myphp || { echo "FAILED: Could find or create the application" && exit 1; }
oc patch dc/${APPLICATION_SERVICE_V1_NAME} -p '{"spec" : { "template" : { "spec" : { "containers" : [ { "name" : "'${APPLICATION_SERVICE_V1_NAME}'", "resources" : { "requests" : { "cpu" : "200m" } } } ] } } } }'
oc get route ${APPLICATION_SERVICE_V1_NAME} || oc expose service ${APPLICATION_SERVICE_V1_NAME} || { echo "FAILED: Could not verify route to ${APPLICATION_SERVICE_V1_NAME} application frontend" && exit 1; }
oc get dc/mysql-${APPLICATION_SERVICE_V1_NAME} || oc new-app mysql-ephemeral --name=mysql-${APPLICATION_SERVICE_V1_NAME} -l app=${OPENSHIFT_APPLICATION_NAME}-${APPLICATION_SERVICE_V2_NAME},part=backend --param=DATABASE_SERVICE_NAME=mysql-${APPLICATION_SERVICE_V1_NAME} --param=MYSQL_USER=myphp --param=MYSQL_PASSWORD=myphp --param=MYSQL_DATABASE=myphp || { echo "FAILED: Could find or create the application" && exit 1; }
oc get svc/${APPLICATION_SERVICE_V1_NAME} && oc patch svc/${APPLICATION_SERVICE_V1_NAME} -p '{"metadata" : { "annotations" : { "service.alpha.openshift.io/dependencies" : "[ { \"name\" : \"mysql-'${APPLICATION_SERVICE_V1_NAME}'\" , \"kind\" : \"Service\"  } ]" } } }' || { echo "FAILED: Could not patch application" && exit 1; }

oc get dc/${APPLICATION_SERVICE_V2_NAME} || oc new-app php:5.6~https://github.com/michaelepley/phpmysqldemo.git#${APPLICATION_SERVICE_V2_NAME} --name=${APPLICATION_SERVICE_V2_NAME} -l app=${OPENSHIFT_APPLICATION_NAME}-${APPLICATION_SERVICE_V2_NAME},part=frontend -e MYSQL_SERVICE_HOST=mysql-${APPLICATION_SERVICE_V2_NAME}.${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}.svc.cluster.local -e MYSQL_SERVICE_PORT=3306 -e MYSQL_SERVICE_DATABASE=myphp -e MYSQL_SERVICE_USERNAME=myphp -e MYSQL_SERVICE_PASSWORD=myphp || { echo "FAILED: Could find or create the application" && exit 1; }
oc patch dc/${APPLICATION_SERVICE_V2_NAME} -p '{"spec" : { "template" : { "spec" : { "containers" : [ { "name" : "'${APPLICATION_SERVICE_V2_NAME}'", "resources" : { "requests" : { "cpu" : "200m" } } } ] } } } }'
oc get route ${APPLICATION_SERVICE_V2_NAME} || oc expose service ${APPLICATION_SERVICE_V2_NAME} || { echo "FAILED: Could not verify route to ${APPLICATION_SERVICE_V2_NAME} application frontend" && exit 1; }
oc get dc/mysql-${APPLICATION_SERVICE_V2_NAME} || oc new-app mysql-ephemeral --name=mysql-${APPLICATION_SERVICE_V2_NAME} -l app=${OPENSHIFT_APPLICATION_NAME}-${APPLICATION_SERVICE_V2_NAME},part=backend --param=DATABASE_SERVICE_NAME=mysql-${APPLICATION_SERVICE_V2_NAME} --param=MYSQL_USER=myphp --param=MYSQL_PASSWORD=myphp --param=MYSQL_DATABASE=myphp || { echo "FAILED: Could find or create the application" && exit 1; }
oc get svc/${APPLICATION_SERVICE_V2_NAME} && oc patch svc/${APPLICATION_SERVICE_V2_NAME} -p '{"metadata" : { "annotations" : { "service.alpha.openshift.io/dependencies" : "[ { \"name\" : \"mysql-'${APPLICATION_SERVICE_V2_NAME}'\" , \"kind\" : \"Service\"  } ]" } } }' || { echo "FAILED: Could not patch application" && exit 1; }


echo "	--> Waiting for the blue and green applications to start....press any key to proceed"
while ! oc get pods | grep blue | grep Running ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""
while ! oc get pods | grep green | grep Running ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""

echo "	--> open web page at ${APPLICATION_SERVICE_V1_NAME}-${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}.${OPENSHIFT_APPS}"
[ "x${DEMO_INTERACTIVE}" != "xfalse" ] && firefox ${APPLICATION_SERVICE_V1_NAME}-${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}.${OPENSHIFT_APPS}

[ "x${DEMO_INTERACTIVE}" != "xfalse" ] && echo "		--> press enter to continue" && read

echo "	--> create new endpoint at visitors.${OPENSHIFT_APPS}"
oc get route visitors || oc expose service ${APPLICATION_SERVICE_V1_NAME} --name visitors -l app=${OPENSHIFT_APPLICATION_NAME} --hostname="visitors.${OPENSHIFT_APPS}"
[ "x${DEMO_INTERACTIVE}" != "xfalse" ] && firefox visitors.${OPENSHIFT_APPS}
[ "x${DEMO_INTERACTIVE}" != "xfalse" ] && echo "		--> press enter to continue" && read

echo "	--> move old endpoint - php-${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}.${OPENSHIFT_APPS} - to new endpoint"
oc patch route/php -p '{"spec" : { "to" : { "name" : "'${APPLICATION_SERVICE_V1_NAME}'"} } }'
[ "x${DEMO_INTERACTIVE}" != "xfalse" ] && firefox php-${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}.${OPENSHIFT_APPS}
[ "x${DEMO_INTERACTIVE}" != "xfalse" ] &&echo "		--> press enter to continue" && read

echo "	--> create new a/b testing endpoint at visitorsab.${OPENSHIFT_APPS}"
oc patch route/php -p '{"spec" : { "to" : { "name" : "php"} } }'
#--session-affinity=None 
oc get route visitorsab || oc expose service ${APPLICATION_SERVICE_V1_NAME} --name visitorsab -l app=${OPENSHIFT_APPLICATION_NAME} --hostname="visitorsab.${OPENSHIFT_APPS}"
[ "x${DEMO_INTERACTIVE}" != "xfalse" ] && firefox visitorsab.${OPENSHIFT_APPS}
[ "x${DEMO_INTERACTIVE}" != "xfalse" ] && echo "		--> press enter to continue" && read

echo "		--> Set the AB endpoint to allow a small amount of traffic to be routed to the 'new' application"
oc set route-backends visitorsab php=90 ${APPLICATION_SERVICE_V1_NAME}=10
for COUNT in {1..20} ; do curl -L -s http://visitorsab.${OPENSHIFT_APPS} | grep -o "bgcolor" || echo "nocolor"; done
[ "x${DEMO_INTERACTIVE}" != "xfalse" ] && echo "			--> notice the small amount of bgcolor application hits" && read
echo "		--> Set the AB endpoint to route traffic equally between applications"
oc set route-backends visitorsab php=50 ${APPLICATION_SERVICE_V1_NAME}=50
for COUNT in {1..20} ; do curl -L -s http://visitorsab.${OPENSHIFT_APPS} | grep -o "bgcolor" || echo "nocolor"; done
[ "x${DEMO_INTERACTIVE}" != "xfalse" ] && echo "			--> notice the equal number of hits for bgcolor and nocolor" && read
echo "		--> Set the AB endpoint to route traffic  mostly to the new application"
oc set route-backends visitorsab php=10 ${APPLICATION_SERVICE_V1_NAME}=90
for COUNT in {1..20} ; do curl -L -s http://visitorsab.${OPENSHIFT_APPS} | grep -o "bgcolor" || echo "nocolor"; done
echo "			--> notice almost all hits are to bgcolor not nocolor"

echo "Done."
