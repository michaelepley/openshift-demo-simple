#!/bin/bash

# Configuration

. ./config.sh

echo "Scaling the frontend"
. ./setup-login.sh
echo "	--> Scaling frontend of application to 4 instances"
echo "		--> Set the resource request to a large value"
oc patch dc/php -p '{"spec" : { "template" : { "spec" : { "containers" : [ { "name" : "php", "resources" : { "limits" : { "cpu" : "1000m" }, "requests" : { "cpu" : "1000m" } } } ] } } } }'
echo "		--> press enter to continue" && read
echo "		--> Find the application replication controller"
OPENSHIFT_APPLICATION_REPLICATION_CONTROLLER=`oc get rc -l app=${OPENSHIFT_APPLICATION_NAME},part=frontend | sed '1d' | awk '$2 > 0 { printf $1 }'` || { echo "FAILED" && exit 1; }
echo "		--> Found ${OPENSHIFT_APPLICATION_REPLICATION_CONTROLLER}"

#oc scale dc/php --replicas=4
oc scale rc/${OPENSHIFT_APPLICATION_REPLICATION_CONTROLLER} --replicas=4

echo "	--> Waiting for pods to start"
for COUNT in {1..20} ; do echo -n "." && sleep 1s; done
echo "		--> Found " $(oc get pods -l part=frontend | tail -n +2 | grep Running | wc -l) pods are running
echo "		--> NOTE: not all pods were able to launch -- the resource quota is preventing everything from running"
echo "		--> press enter to continue" && read
echo "	--> Scale application back down to just 2 replicas"
oc scale rc/${OPENSHIFT_APPLICATION_REPLICATION_CONTROLLER} --replicas=2
echo "		--> press enter to continue" && read
echo "	--> Setting lower resource request for php template"
echo "		--> CPU limit now 400 millicores, request 200 millicores"
oc patch dc/php -p '{"spec" : { "template" : { "spec" : { "containers" : [ { "name" : "php", "resources" : { "limits" : { "cpu" : "400m" }, "requests" : { "cpu" : "200m" } } } ] } } } }'
echo "		--> press enter to continue" && read
echo "	--> Retry Scaling application to 4 instances"
oc scale dc/php --replicas=4
echo "	--> Waiting for pods to start"
for COUNT in {1..20} ; do echo -n "." && sleep 1s; done
echo "		--> Found " $(oc get pods -l part=frontend | tail -n +2 | wc -l) " pods are running"
echo "		--> press enter to continue" && read
echo "	--> Forcefully destroy the original pod"
echo "		--> Attempting to locate an original pod"
OPENSHIFT_PHP_POD_ORIGINAL=`oc get pods | grep Running | grep '^php-'$(oc get dc/php --template={{.status.latestVersion}}) | sed '1d' | head -n 1 | awk '{printf $1}'` || { echo "FAILED" && exit 1; }
echo "		--> Deleting the pod ${OPENSHIFT_PHP_POD_ORIGINAL}"
oc delete pod ${OPENSHIFT_PHP_POD_ORIGINAL}
echo "		--> press enter to continue" && read
echo "	--> Set up autoscaling"
echo "		--> a minimum of 1 pod, a maximum of 5 pods, and scale at 30% capacity"
oc autoscale dc/php --min=1 --max=5 --cpu-percent=30
echo "		--> Found " $(oc get pods -l part=frontend | tail -n +2 | wc -l) " pods are running"
read -t 1
echo "	--> Driving some load"
echo "		--> Issuing requests to http://php-${OPENSHIFT_PRIMARY_PROJECT_MYSQLPHP_DEFAULT}.${OPENSHIFT_PRIMARY_APPS}/load/primality.php?number=100000 "
echo "		--> Issuing requests to http://php-${OPENSHIFT_PRIMARY_PROJECT_MYSQLPHP_DEFAULT}.${OPENSHIFT_PRIMARY_APPS}/load/request.php?t=1000 "
echo "		--> Press any key to abort"
while [ true ] ; do
	curl -L -s http://php-${OPENSHIFT_PRIMARY_PROJECT_MYSQLPHP_DEFAULT}.${OPENSHIFT_PRIMARY_APPS}/load/primality.php?number=100000 >> /dev/null 2>&1 &
	curl -L -s http://php-${OPENSHIFT_PRIMARY_PROJECT_MYSQLPHP_DEFAULT}.${OPENSHIFT_PRIMARY_APPS}/load/request.php?t=1000 >> /dev/null 2>&1 &
	echo -n "." && read -t 1 -n 1
	[ $? = 0 ] && break
done

echo "		--> Found " $(oc get pods -l part=frontend | tail -n +2 | wc -l) " pods are running"
echo "Done"
