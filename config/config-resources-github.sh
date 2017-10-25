#!/bin/bash

. config-resources-available-all.sh || { echo "FAILED: Could not load available resource index" && exit 1; }

[[ -v CONFIGURATION_RESOURCES_GITHUB_COMPLETED ]] && echo "	--> Using github resources configuration" && { return || exit ; }
: ${CONFIGURATION_RESOURCES_GITHUB_DISPLAY:=$CONFIGURATION_DISPLAY}

# Verify availability of and access to GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT
# if available, use GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT, then leave behind GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT and encrypted with SCRIPT_ENCRYPTION_KEY
# otherwise use GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT and decrypt with SCRIPT_ENCRYPTION_KEY

GITHUB_USERS=(michaelepley)
GITHUB_USER_PRIMARY=${GITHUB_USERS[0]}
GITHUB_AUTHORIZATION_ROLES_REQUIRED=(none)

# get encryption/decryption key if one is not provided automatically
[[ -v SCRIPT_ENCRYPTION_KEY ]] || { read -t 10 -s -p "======> ENTER ENCRYPTION/DECRYPTION KEY:" SCRIPT_ENCRYPTION_KEY && echo "" ; }
# assume a default key if the user did not supply one in time
: ${SCRIPT_ENCRYPTION_KEY:=$OPENSHIFT_USER_PRIMARY_PASSWORD}

[[ -v GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT ]] || [[ -v GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT ]] || { echo "FAILED: GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT must be set and match a valid GitHub.com Oauth2 personal access token with the following roles:" ; }
#GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT=`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY} `
[[ -v GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT ]] && ! [[ -v GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT ]] && echo "--> it is recommended to use an encrypted token; you may encrypt and store the token using the following: " && echo ' GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT=`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT} | openssl enc -e -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY} | openssl enc -e -a`'
[[ -v GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT ]] && { : ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:=`echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a | openssl enc -d -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY}`} || { echo "FAILED: Could not validate the github token" && exit 1; } ; }

echo -n "	--> Verify access to github.com..."
ping -W 1 -c 2 api.github.com >>/dev/null 2>&1 || { echo "FAILED: Could not access github.com, check your network connection" && exit 1; }
echo "OK"

if [ "$CONFIGURATION_RESOURCES_GITHUB_DISPLAY" != "false" ]; then
	echo "Demo Resources GITHUB Configuration__________________________"
	echo "	GITHUB_USER_PRIMARY                                      = ${GITHUB_USER_PRIMARY}"
	echo "	GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT     = `echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT} | md5sum` (obfuscated)"
	echo "	GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT     = ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT}"
	echo "____________________________________________________________"
fi

CONFIGURATION_RESOURCES_GITHUB_COMPLETED=true
