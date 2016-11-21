#!/bin/bash

# Configuration

. ./config.sh

echo "Just logs in"
if ( oc whoami 2>/dev/null | grep ${OPENSHIFT_PRIMARY_USER} && oc whoami -c | grep ${OPENSHIFT_DOMAIN} ) ; then
	echo "	--> already logged in to openshift"
else
echo "	--> Determining login method"
case ${OPENSHIFT_PRIMARY_AUTH_METHOD_DEFAULT} in
	${OPENSHIFT_PRIMARY_AUTH_METHODS[0]} )
		echo "	--> Configuring for ${OPENSHIFT_PRIMARY_AUTH_METHODS[0]} authentication"
	;;
	${OPENSHIFT_PRIMARY_AUTH_METHODS[1]} )
		echo "	--> Configuring for ${OPENSHIFT_PRIMARY_AUTH_METHODS[1]} authentication"
		echo "FAILED: kerberos auth not currently supported" && exit 1
	;;
	${OPENSHIFT_PRIMARY_AUTH_METHODS[2]} )
		echo "	--> Configuring for ${OPENSHIFT_PRIMARY_AUTH_METHODS[2]} authentication"
		{ [[ -v OPENSHIFT_PRIMARY_USER_TOKEN ]] || [[ -z ${OPENSHIFT_PRIMARY_USER_TOKEN} ]] ; } && { echo "	--> attempt to obtain the oauth authorization token automatically" && OPENSHIFT_PRIMARY_USER_TOKEN=`curl -sS -u ${OPENSHIFT_PRIMARY_USER}:${OPENSHIFT_PRIMARY_USER_PASSWORD} -kv -H "X-CSRF-Token: xxx" "https://${OPENSHIFT_PRIMARY_PROXY_AUTH}/challenging-proxy/oauth/authorize?client_id=openshift-challenging-client&response_type=token" 2>&1 | sed -e '\|access_token|!d;s/.*access_token=\([-_[:alnum:]]*\).*/\1/'` && echo "		-> token is ${OPENSHIFT_PRIMARY_USER_TOKEN}" ; }  
		{ [[ -v OPENSHIFT_PRIMARY_USER_TOKEN ]] && [[ -n ${OPENSHIFT_PRIMARY_USER_TOKEN} ]] ; } || { echo "Please set OPENSHIFT_PRIMARY_USER_TOKEN to your openshift login token" && exit 1; }
		OPENSHIFT_PRIMARY_CEREDENTIALS_CLI_DEFAULT="--token ${OPENSHIFT_PRIMARY_USER_TOKEN}"
		OPENSHIFT_PRIMARY_CEREDENTIALS_CLI=${OPENSHIFT_PRIMARY_CEREDENTIALS_CLI_DEFAULT}
	;;
	${OPENSHIFT_PRIMARY_AUTH_METHODS[3]} )
		echo "	--> Configuring for ${OPENSHIFT_PRIMARY_AUTH_METHODS[3]} authentication"
		echo "FAILED: cert auth not currently supported" && exit 1
	;;
	*)
		echo "FAILED: unknown authentication method selected" && exit 1
	;;
esac

echo "	--> Log into openshift"
{ oc whoami 2>/dev/null && oc whoami -c | grep ${OPENSHIFT_PRIMARY_MASTER} ; } || { oc login ${OPENSHIFT_PRIMARY_MASTER}:${OPENSHIFT_PRIMARY_MASTER_PORT_HTTPS} ${OPENSHIFT_PRIMARY_CEREDENTIALS_CLI} --insecure-skip-tls-verify=false; }  || { echo "FAILED: could not login to openshift" && exit 1; }
fi
echo "	--> Switch to project"
oc project ${OPENSHIFT_PRIMARY_PROJECT} || { echo "FAILED: Could not use indicated project" && exit 1; }
