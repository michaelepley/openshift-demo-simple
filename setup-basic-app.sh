#!/bin/bash

# Configuration

. ./config-demo-openshift-simple.sh || { echo "FAILED: could not initialize demo configuration" && exit 1; }

echo "	--> Setting up php frontend application"
. ./setup-php.sh
echo "		--> press enter to continue" && read
echo "	--> Setting up database backend application"
. ./setup-db.sh
echo "		--> press enter to continue" && read
echo "	--> Connecting the frontend and backend"
. ./setup-connect.sh
echo "Done."