#!/bin/bash

# Configuration

{ [[ -v CONFIGURATION_COMPLETED ]] && echo "Using preloaded configuration"; } || . ./config.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

: ${CONFIGURATION_SETUP_LOGIN_DISPLAY:=$CONFIGURATION_DISPLAY}
CONFIGURATION_SETUP_LOGIN_DISPLAY=true

echo "Just logs in"
echo "	--> checking input parameters"
# set defaults for required input parameters
SCRIPT_ARG_DOMAIN=${OPENSHIFT_DOMAIN_DEFAULT}
SCRIPT_ARG_USERNAME=${OPENSHIFT_USER_PRIMARY_DEFAULT}
SCRIPT_ARG_PASSWORD=${OPENSHIFT_USER_PRIMARY_PASSWORD_DEFAULT}
SCRIPT_ARG_PROJECT=${OPENSHIFT_PROJECT_PRIMARY_DEFAULT}
SCRIPT_ARG_PROJECT_DESCRIPTION=${OPENSHIFT_PROJECT_DESCRIPTION}
SCRIPT_ARG_PROJECT_DISPLAY_NAME=${OPENSHIFT_PROJECT_DISPLAY_NAME}
SCRIPT_ARG_AUTH_METHOD=${OPENSHIFT_AUTH_METHOD_PRIMARY_DEFAULT}
SCRIPT_ARG_AUTH_PROXY=${OPENSHIFT_PROXY_AUTH_PRIMARY_DEFAULT}
SCRIPT_ARG_MASTER=${OPENSHIFT_MASTER_PRIMARY_DEFAULT}
SCRIPT_ARG_MASTER_PORT_HTTPS=${OPENSHIFT_MASTER_PRIMARY_DEFAULT_PORT_HTTPS}

# check for a user reference, which will set initial parameter values, which can be overridden by specific settings
SCRIPT_COMMANDLINE_OPTION_OPENSHIFT_USER_REF=(`getopt -o r: --long reference: -n 'setup-login.sh' -- "$@"`)

eval "SCRIPT_ARG_REFERENCE=${SCRIPT_COMMANDLINE_OPTION_OPENSHIFT_USER_REF:+${SCRIPT_COMMANDLINE_OPTION_OPENSHIFT_USER_REF[1]}}"

if [ "x${SCRIPT_ARG_REFERENCE}" != "x" ] ; then 
echo "User reference found $SCRIPT_ARG_REFERENCE "
[[ -v ${SCRIPT_ARG_REFERENCE} ]] || { echo "FAILED: reference ${SCRIPT_ARG_REFERENCE} is invalid" && exit 1; }
SCRIPT_ARG_REFERENCE_USERNAME_REF=${!SCRIPT_ARG_REFERENCE}[0]
SCRIPT_ARG_REFERENCE_PASSWORD_REF=${!SCRIPT_ARG_REFERENCE}[1]
SCRIPT_ARG_REFERENCE_AUTH_METHOD_REF=${!SCRIPT_ARG_REFERENCE}[2]
SCRIPT_ARG_REFERENCE_PROJECT_REF=${!SCRIPT_ARG_REFERENCE}[3]

echo "Reference decomposition______________________________________"
echo "SCRIPT_ARG_REFERENCE_USERNAME_REF       = ${SCRIPT_ARG_REFERENCE_USERNAME_REF}"
echo "SCRIPT_ARG_REFERENCE_PASSWORD_REF       = ${SCRIPT_ARG_REFERENCE_PASSWORD_REF}"
echo "SCRIPT_ARG_REFERENCE_AUTH_METHOD_REF    = ${SCRIPT_ARG_REFERENCE_AUTH_METHOD_REF}"
echo "SCRIPT_ARG_REFERENCE_PROJECT_REF        = ${SCRIPT_ARG_REFERENCE_PROJECT_REF}"

SCRIPT_ARG_USERNAME=${!SCRIPT_ARG_REFERENCE_USERNAME_REF}
SCRIPT_ARG_PASSWORD=${!SCRIPT_ARG_REFERENCE_PASSWORD_REF}
SCRIPT_ARG_AUTH_METHOD=${!SCRIPT_ARG_REFERENCE_AUTH_METHOD_REF}
SCRIPT_ARG_PROJECT=${!SCRIPT_ARG_REFERENCE_PROJECT_REF}
#else
#	echo "_______________________________NO REFERENCE FOUND_________________________________"
fi


# read all other options -- see http://www.bahmanm.com/blogs/command-line-options-how-to-parse-in-bash-using-getopt 
SCRIPT_COMMANDLINE_OPTIONS=`getopt -o d:u:p:r:a:x:m:n: --long domain:,username:,password:,reference:,auth-method:,auth-proxy:,master:,namespace: -n 'setup-login.sh' -- "$@"`
eval set -- "$SCRIPT_COMMANDLINE_OPTIONS"



# extract options and their arguments into variables.
while true ; do
	case "$1" in
		-d|--domain)
			case "$2" in
				"") shift 2 ;;
				*) SCRIPT_ARG_DOMAIN=$2 ; shift 2 ;;
			esac ;;
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
		-n|--namespace)
			case "$2" in
				"") shift 2 ;;
				*) SCRIPT_ARG_PROJECT=$2 ; shift 2 ;;
			esac ;;
		--) shift ; break ;;
		*) echo "Internal error!" ; exit 1 ;;
	esac
done

if [ "$CONFIGURATION_SETUP_LOGIN_DISPLAY" != "false" ]; then
	echo "Setup Login Configuration___________________________________"
	echo "SCRIPT_ARG_REFERENCE= ${SCRIPT_ARG_REFERENCE}"
	echo "SCRIPT_ARG_DOMAIN = ${SCRIPT_ARG_DOMAIN}"
	echo "SCRIPT_ARG_USERNAME = ${SCRIPT_ARG_USERNAME}"
	echo "SCRIPT_ARG_PASSWORD = ${SCRIPT_ARG_PASSWORD}"
	echo "SCRIPT_ARG_PROJECT  = ${SCRIPT_ARG_PROJECT}"
	echo "SCRIPT_ARG_AUTH_METHOD = ${SCRIPT_ARG_AUTH_METHOD}"
	echo "SCRIPT_ARG_AUTH_PROXY = ${SCRIPT_ARG_AUTH_PROXY}"
	echo "SCRIPT_ARG_MASTER = ${SCRIPT_ARG_MASTER}"
	echo "SCRIPT_ARG_MASTER_PORT_HTTPS = ${SCRIPT_ARG_MASTER_PORT_HTTPS}"
	echo "____________________________________________________________"
fi

echo -n "Verifying configuration ready..."
: ${SCRIPT_ARG_DOMAIN?}
: ${SCRIPT_ARG_USERNAME?}
: ${SCRIPT_ARG_PASSWORD?}
: ${SCRIPT_ARG_PROJECT?}
: ${SCRIPT_ARG_AUTH_METHOD}
: ${SCRIPT_ARG_AUTH_PROXY}
: ${SCRIPT_ARG_MASTER}
: ${SCRIPT_ARG_MASTER_PORT_HTTPS}
echo "OK"

oc whoami >/dev/null 2>&1 || echo "not Logged in"
oc whoami >/dev/null 2>&1  && { [[ "`oc whoami 2>/dev/null 2>&1`" != "${SCRIPT_ARG_USERNAME}" ]] || oc whoami -c >/dev/null 2>&1  | grep -v ${SCRIPT_ARG_DOMAIN} ; } && { echo "Logging out user" && oc logout ; }

if ( oc whoami 2>/dev/null == "${SCRIPT_ARG_USERNAME}" && oc whoami -c | grep ${SCRIPT_ARG_DOMAIN} ) ; then
	echo "	--> already logged in to openshift"
else
	echo "	--> Determining login method"
	case ${SCRIPT_ARG_AUTH_METHOD} in
		${OPENSHIFT_PRIMARY_AUTH_METHODS[0]} )
			# password auth
			echo "	--> Configuring for ${OPENSHIFT_PRIMARY_AUTH_METHODS[0]} authentication"
			OPENSHIFT_PRIMARY_CEREDENTIALS_CLI='--username='${SCRIPT_ARG_USERNAME}' --password='${SCRIPT_ARG_PASSWORD}
		;;
		${OPENSHIFT_PRIMARY_AUTH_METHODS[1]} )
			# kerberos auth
			echo "	--> Configuring for ${OPENSHIFT_PRIMARY_AUTH_METHODS[1]} authentication"
			echo "FAILED: kerberos auth not currently supported" && exit 1
		;;
		${OPENSHIFT_PRIMARY_AUTH_METHODS[2]} )
			# token auth
			echo "	--> Configuring for ${OPENSHIFT_PRIMARY_AUTH_METHODS[2]} authentication"
			
			{ [[ -v OPENSHIFT_USER_PRIMARY_TOKEN ]] || [[ -z ${OPENSHIFT_USER_PRIMARY_TOKEN} ]] ; } && { echo "	--> attempt to obtain the oauth authorization token from ${SCRIPT_ARG_AUTH_PROXY} automatically for user ${SCRIPT_ARG_USERNAME}" && OPENSHIFT_USER_PRIMARY_TOKEN=$(curl -sS -u "${SCRIPT_ARG_USERNAME}":"${SCRIPT_ARG_PASSWORD}" -kv -H "X-CSRF-Token:xxx" "https://${SCRIPT_ARG_AUTH_PROXY}/challenging-proxy/oauth/authorize?client_id=openshift-challenging-client&response_type=token" 2>&1 | sed -e '\|access_token|!d;s/.*access_token=\([-_[:alnum:]]*\).*/\1/') && echo "		-> token is ${OPENSHIFT_USER_PRIMARY_TOKEN}" ; }  
			{ [[ -v OPENSHIFT_USER_PRIMARY_TOKEN ]] && [[ -n ${OPENSHIFT_USER_PRIMARY_TOKEN} ]] ; } || { echo "Please set OPENSHIFT_USER_PRIMARY_TOKEN to your openshift login token" && exit 1; }
			OPENSHIFT_PRIMARY_CEREDENTIALS_CLI_DEFAULT="--token ${OPENSHIFT_USER_PRIMARY_TOKEN}"
			OPENSHIFT_PRIMARY_CEREDENTIALS_CLI=${OPENSHIFT_PRIMARY_CEREDENTIALS_CLI_DEFAULT}
		;;
		${OPENSHIFT_PRIMARY_AUTH_METHODS[3]} )
			# certificate auth
			echo "	--> Configuring for ${OPENSHIFT_PRIMARY_AUTH_METHODS[3]} authentication"
			echo "FAILED: cert auth not currently supported" && exit 1
		;;
		*)
			echo "FAILED: unknown authentication method ${SCRIPT_ARG_AUTH_METHOD} selected" && exit 1
		;;
	esac
	
	echo "	--> Log into openshift"
	{ oc whoami 2>/dev/null && oc whoami -c | grep ${SCRIPT_ARG_MASTER} ; } || { oc login ${SCRIPT_ARG_MASTER}:${SCRIPT_ARG_MASTER_PORT_HTTPS} ${OPENSHIFT_PRIMARY_CEREDENTIALS_CLI} --insecure-skip-tls-verify=false; }  || { echo "FAILED: could not login to openshift" && exit 1; }
	# record the user
	OPENSHIFT_USER=${SCRIPT_ARG_USERNAME}
fi
echo "	--> Switch to the ${SCRIPT_ARG_PROJECT} project, creating it if necessary"
{ oc get project ${SCRIPT_ARG_PROJECT} 2>&1 >/dev/null && oc project ${SCRIPT_ARG_PROJECT}; } || oc new-project ${SCRIPT_ARG_PROJECT} ${SCRIPT_ARG_PROJECT_DESCRIPTION:+"--description"} ${SCRIPT_ARG_PROJECT_DESCRIPTION} ${SCRIPT_ARG_PROJECT_DISPLAY_NAME:+"--display-name"} ${SCRIPT_ARG_PROJECT_DISPLAY_NAME} || { echo "FAILED: Could not use indicated project ${SCRIPT_ARG_PROJECT}" && exit 1; }
# record the current project
OPENSHIFT_PROJECT=${SCRIPT_ARG_PROJECT}
OPENSHIFT_PROJECT_DESCRIPTION=${SCRIPT_ARG_PROJECT_DESCRIPTION}
OPENSHIFT_PROJECT_DISPLAY_NAME=${SCRIPT_ARG_PROJECT_DISPLAY_NAME}
echo "Done."

