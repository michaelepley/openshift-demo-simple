#!/bin/bash

# Configuration

. ./config-demo-openshift-simple.sh || { echo "FAILED: could not initialize demo configuration" && exit 1; }

echo "Running simple openshift demo"

echo "	--> Logging into openshift"
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT_PRIMARY_MYSQLPHP}
echo "	--> Setting up php frontend application"
. ./setup-php.sh
echo "		--> press enter to continue" && read
echo "	--> Setting up database backend application"
. ./setup-db.sh
echo "		--> press enter to continue" && read
echo "	--> Connecting the frontend and backend"
. ./setup-connect.sh
echo "		--> press enter to continue" && read
echo "	--> Scale the frontend"
. ./setup-scale.sh
echo "		--> press enter to continue" && read
echo "	--> Deploy some different versions of the application"
. ./setup-versions.sh
echo "		--> press enter to continue" && read
echo "	--> Enhance the build process of the application"
. ./setup-builds.sh
echo "		--> press enter to continue" && read

echo "	--> use clean.sh to cleanup"
echo "Done."
