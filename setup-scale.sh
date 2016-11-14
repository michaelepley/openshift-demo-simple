#!/bin/bash

# Configuration

. ./config.sh

echo "	--> Attempting to locate original pod"
OPENSHIFT_PHP_POD_ORIGINAL=`oc get pods | grep Running | grep '^php-'$(oc get dc/php --template={{.status.latestVersion}}) | sed '1d' | head -n 1 | awk '{printf $1}'` || { echo "FAILED" && exit 1; }
echo "	--> Find the application replication controller"
OPENSHIFT_APPLICATION_REPLICATION_CONTROLLER=`oc get rc -l app=${OPENSHIFT_APPLICATION_NAME} | sed '1d' | awk '$2 > 0 { printf $1 }'` || { echo "FAILED" && exit 1; }
echo "		--> Found ${OPENSHIFT_APPLICATION_REPLICATION_CONTROLLER}"
echo "	--> Scaling frontend of application to 4 instances"
# oc scale rc/${OPENSHIFT_APPLICATION_REPLICATION_CONTROLLER} --replicas=4
oc scale dc/php --replicas=4

echo "	--> Waiting for pods to start"
for COUNT in {1..20} ; do echo -n "." && sleep 1s; done
echo "		--> Found " $(oc get pods | grep Running | grep '^php' | wc -l) pods are running
echo "		--> NOTE: not all pods were able to launch -- the resource quota is preventing everything from running"
echo "		--> press enter to continue" && read
echo "	--> Scale application back down to just 2 replicas"
oc scale dc/php --replicas=2
echo "		--> press enter to continue" && read
echo "	--> Setting lower resource request for php template"
oc patch dc/php -p '{"spec" : { "template" : { "spec" : { "containers" : [ { "name" : "php", "resources" : { "requests" : { "cpu" : "200m" } } } ] } } } }'
echo "		--> press enter to continue" && read
echo "	--> Retry Scaling application to 4 instances"
oc scale dc/php --replicas=4
echo "	--> Waiting for pods to start"
for COUNT in {1..20} ; do echo -n "." && sleep 1s; done
echo "		--> Found " $(oc get pods | grep '^php' | wc -l) "pods are running"
echo "		--> press enter to continue" && read
echo "	--> Forcefully destroy the original pod"
oc delete pod ${OPENSHIFT_PHP_POD_ORIGINAL}
echo "		--> press enter to continue" && read
echo "	--> Set up autoscaling"
oc autoscale dc/php --min=1 --max=5 --cpu-percent=80
echo "		--> Found " $(oc get pods | grep '^php' | wc -l) "pods are running"
echo "	--> Driving some load"
echo "		--> TODO: make a load generating applicaton"
for COUNT in {1..20} ; do curl -L -s http://php-${OPENSHIFT_APPLICATION_NAME}.${OPENSHIFT_PRIMARY_APPS} >> /dev/null ; done
echo "		--> Found " $(oc get pods | grep '^php' | wc -l) "pods are running"
echo "Done"
