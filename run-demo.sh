#!/bin/bash

echo "Running simple openshift demo"
echo "	--> Setting up php frontend application"
. ./setup-php.sh
read
echo "	--> Setting up database backend application"
. ./setup-db.sh
read
echo "	--> Connecting the frontend and backend"
. ./setup-connect.sh
read
echo "	--> Scale the frontend"
. ./setup-scale.sh
read
echo "	--> Deploy some different versions of the application"
. ./setup-versions.sh
read
echo "	--> use clean.sh to cleanup"
echo "Done."
