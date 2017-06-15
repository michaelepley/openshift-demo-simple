#!/bin/bash

# Configuration

{ [[ -v CONFIGURATION_COMPLETED ]] && echo "Using preloaded configuration"; } || . ./config.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

echo "Just logs in"
echo "	--> checking input parameters"
# set defaults for required input parameters
SCRIPT_ARG_USERNAME=${OPENSHIFT_USER}
SCRIPT_ARG_PASSWORD=${OPENSHIFT_PASSWORD}
SCRIPT_ARG_PROJECT=${OPENSHIFT_PROJECT}
SCRIPT_ARG_PROJECT_DESCRIPTION=${OPENSHIFT_PROJECT_DESCRIPTION}
SCRIPT_ARG_PROJECT_DISPLAY_NAME=${OPENSHIFT_PROJECT_DISPLAY_NAME}
SCRIPT_ARG_AUTH_METHOD=${OPENSHIFT_AUTH_METHOD}
SCRIPT_ARG_AUTH_PROXY=${OPENSHIFT_AUTH_PROXY}
SCRIPT_ARG_MASTER=${OPENSHIFT_MASTER}


# read the options -- see http://www.bahmanm.com/blogs/command-line-options-how-to-parse-in-bash-using-getopt 
SCRIPT_COMMANDLINE_OPTIONS=`getopt -o u:p:r:a:x:m: --long username:,password:,reference:,auth-method:,auth-proxy:,master: -n 'setup-login.sh' -- "$@"`
eval set -- "$SCRIPT_COMMANDLINE_OPTIONS"

# extract options and their arguments into variables.
while true ; do
	case "$1" in
		-u|--username)
			case "$2" in
				"") shift 2 ;;
				*) SCRIPT_ARG_USERNAME=$2 ; shift 2 ;;
			esac ;;
		-p|--password)
			case "$2" in
				"") shift 2 ;;
				*) SCRIPT_ARG_PASSWORD=$2 ; shift 2 ;;
			esac ;;
		-r|--reference)
			case "$2" in
				"") shift 2 ;;
				*) SCRIPT_ARG_REFERENCE=$2 ; shift 2 ;;
			esac ;;
		-a|--auth-method)
			case "$2" in
				"") shift 2 ;;
				*) SCRIPT_ARG_AUTH_METHOD=$2 ; shift 2 ;;
			esac ;;
		-x|--auth-proxy)
			case "$2" in
				"") shift 2 ;;
				*) SCRIPT_ARG_AUTH_PROXY=$2 ; shift 2 ;;
			esac ;;
		-m|--master)
			case "$2" in
				"") shift 2 ;;
				*) SCRIPT_ARG_AUTH_MASTER=$2 ; shift 2 ;;
			esac ;;
		--) shift ; break ;;
		*) echo "Internal error!" ; exit 1 ;;
	esac
done

if [[ -v SCRIPT_ARG_REFERENCE ]] ; then 
# echo "User reference found $SCRIPT_ARG_REFERENCE "
[[ -v ${SCRIPT_ARG_REFERENCE} ]] || { echo "FAILED: reference ${SCRIPT_ARG_REFERENCE} is invalid" && exit 1; }
SCRIPT_ARG_REFERENCE_USERNAME_REF=${SCRIPT_ARG_REFERENCE}[0]
SCRIPT_ARG_REFERENCE_PASSWORD_REF=${SCRIPT_ARG_REFERENCE}[1]
SCRIPT_ARG_REFERENCE_PROJECT_REF=${SCRIPT_ARG_REFERENCE}[2]
SCRIPT_ARG_USERNAME=${!SCRIPT_ARG_REFERENCE_USERNAME_REF}
SCRIPT_ARG_PASSWORD=${!SCRIPT_ARG_REFERENCE_PASSWORD_REF}
SCRIPT_ARG_PROJECT=${!SCRIPT_ARG_REFERENCE_PROJECT_REF}

fi

# echo "COMMANDLINE PARAMETERS VALIDATION: SCRIPT_ARG_USERNAME = ${SCRIPT_ARG_USERNAME} , SCRIPT_ARG_PASSWORD = ${SCRIPT_ARG_PASSWORD} , SCRIPT_ARG_PROJECT  = ${SCRIPT_ARG_PROJECT} , SCRIPT_ARG_AUTH_METHOD = ${OPENSHIFT_AUTH_METHOD} , SCRIPT_ARG_AUTH_PROXY = ${OPENSHIFT_AUTH_PROXY} , SCRIPT_ARG_MASTER = ${OPENSHIFT_MASTER}"


oc whoami 2>&1 > /dev/null || echo "not Logged in"
oc whoami 2>&1 > /dev/null && [[ `oc whoami 2>/dev/null` != ${SCRIPT_ARG_USERNAME} || `oc whoami 2>/dev/null -c | grep ${OPENSHIFT_DOMAIN} | wc -l` == 0 ]] && { echo "Logging out user" && oc logout ; }

if ( oc whoami 2>/dev/null == "${SCRIPT_ARG_USERNAME}" && oc whoami -c | grep ${OPENSHIFT_DOMAIN} ) ; then
	echo "	--> already logged in to openshift"
else
	echo "	--> Determining login method"
	case ${OPENSHIFT_PRIMARY_AUTH_METHOD_DEFAULT} in
		${OPENSHIFT_PRIMARY_AUTH_METHODS[0]} )
			echo "	--> Configuring for ${OPENSHIFT_PRIMARY_AUTH_METHODS[0]} authentication"
			if [[ -v OPENSHIFT_RHSADEMO_USER_PASSWORD_DEFAULT ]] ; then
				echo "--> Using RHSADEMO password for openshift"
				OPENSHIFT_USER_PRIMARY_PASSWORD_DEFAULT=$OPENSHIFT_RHSADEMO_USER_PASSWORD_DEFAULT
			else
				[[ ! -v OPENSHIFT_USER_PRIMARY_PASSWORD_DEFAULT ]] && echo "Please set OPENSHIFT_USER_PRIMARY_PASSWORD_DEFAULT to your openshift password" && exit 1
			fi
			SCRIPT_ARG_USERNAME=${OPENSHIFT_USER_PRIMARY_DEFAULT}
			SCRIPT_ARG_PASSWORD=${OPENSHIFT_USER_PRIMARY_PASSWORD_DEFAULT}
			OPENSHIFT_PRIMARY_CEREDENTIALS_CLI='--username='${SCRIPT_ARG_USERNAME}' --password='${SCRIPT_ARG_PASSWORD}
		;;
		${OPENSHIFT_PRIMARY_AUTH_METHODS[1]} )
			echo "	--> Configuring for ${OPENSHIFT_PRIMARY_AUTH_METHODS[1]} authentication"
			echo "FAILED: kerberos auth not currently supported" && exit 1
		;;
		${OPENSHIFT_PRIMARY_AUTH_METHODS[2]} )
			echo "	--> Configuring for ${OPENSHIFT_PRIMARY_AUTH_METHODS[2]} authentication"
						
			{ [[ -v OPENSHIFT_USER_PRIMARY_TOKEN ]] || [[ -z ${OPENSHIFT_USER_PRIMARY_TOKEN} ]] ; } && { echo "	--> attempt to obtain the oauth authorization token automatically for user ${SCRIPT_ARG_USERNAME}" && OPENSHIFT_USER_PRIMARY_TOKEN=$(curl -sS -u "${SCRIPT_ARG_USERNAME}":"${SCRIPT_ARG_PASSWORD}" -kv -H "X-CSRF-Token:xxx" "https://${OPENSHIFT_PRIMARY_PROXY_AUTH}/challenging-proxy/oauth/authorize?client_id=openshift-challenging-client&response_type=token" 2>&1 | sed -e '\|access_token|!d;s/.*access_token=\([-_[:alnum:]]*\).*/\1/') && echo "		-> token is ${OPENSHIFT_USER_PRIMARY_TOKEN}" ; }  
			{ [[ -v OPENSHIFT_USER_PRIMARY_TOKEN ]] && [[ -n ${OPENSHIFT_USER_PRIMARY_TOKEN} ]] ; } || { echo "Please set OPENSHIFT_USER_PRIMARY_TOKEN to your openshift login token" && exit 1; }
			OPENSHIFT_PRIMARY_CEREDENTIALS_CLI_DEFAULT="--token ${OPENSHIFT_USER_PRIMARY_TOKEN}"
			OPENSHIFT_PRIMARY_CEREDENTIALS_CLI=${OPENSHIFT_PRIMARY_CEREDENTIALS_CLI_DEFAULT}
		;;
		${OPENSHIFT_PRIMARY_AUTH_METHODS[3]} )
			echo "	--> Configuring for ${OPENSHIFT_PRIMARY_AUTH_METHODS[3]} authentication"
			echo "FAILED: cert auth not currently supported" && exit 1
		;;
		*)
			echo "FAILED: unknown authentication method ${OPENSHIFT_PRIMARY_AUTH_METHOD_DEFAULT} selected" && exit 1
		;;
	esac
	
	echo "	--> Log into openshift"
	{ oc whoami 2>/dev/null && oc whoami -c | grep ${OPENSHIFT_PRIMARY_MASTER} ; } || { oc login ${OPENSHIFT_PRIMARY_MASTER}:${OPENSHIFT_PRIMARY_MASTER_PORT_HTTPS} ${OPENSHIFT_PRIMARY_CEREDENTIALS_CLI} --insecure-skip-tls-verify=false; }  || { echo "FAILED: could not login to openshift" && exit 1; }
	# record the user
	OPENSHIFT_USER=${SCRIPT_ARG_USERNAME}
fi
echo "	--> Switch to the project, creating it if necessary"
{ oc get project ${SCRIPT_ARG_PROJECT} 2>&1 >/dev/null && oc project ${SCRIPT_ARG_PROJECT}; } || oc new-project ${SCRIPT_ARG_PROJECT} ${SCRIPT_ARG_PROJECT_DESCRIPTION:+"--description"} ${SCRIPT_ARG_PROJECT_DESCRIPTION} ${SCRIPT_ARG_PROJECT_DISPLAY_NAME:+"--display-name"} ${SCRIPT_ARG_PROJECT_DISPLAY_NAME} || { echo "FAILED: Could not use indicated project ${SCRIPT_ARG_PROJECT}" && exit 1; }
# record the current project
OPENSHIFT_PROJECT=${SCRIPT_ARG_PROJECT}
OPENSHIFT_PROJECT_DESCRIPTION=${SCRIPT_ARG_PROJECT_DESCRIPTION}
OPENSHIFT_PROJECT_DISPLAY_NAME=${SCRIPT_ARG_PROJECT_DISPLAY_NAME}
echo "Done."

