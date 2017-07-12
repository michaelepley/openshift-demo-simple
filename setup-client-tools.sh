#!/bin/bash

# Configuration

. ./config.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

echo "Setup client tools"
echo "	--> verify access to the oc client tools"
command -v oc  || sudo dnf install -y origin-clients || { "Could not verify access to the openshift CLI, please install before proceeding" && exit 1; }
echo "	--> checking minimum version of the client tools"

OPENSHIFT_CLIENT_DETECTED=`oc version 2>/dev/null | sed -e '\|^oc\sv.*|!d;s|^oc\sv||'`
OPENSHIFT_CLIENT_MINIMUM=3.4

sort --check --version-sort <<< ${OPENSHIFT_CLIENT_MINIMUM}$'\n'${OPENSHIFT_CLIENT_DETECTED} || { echo "Could not verify the required version of the openshift client tools are available. Detected version ${OPENSHIFT_CLIENT_DETECTED}, but this requires ${OPENSHIFT_CLIENT_MINIMUM}." && exit 1; } 
