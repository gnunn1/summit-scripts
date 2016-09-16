#!/usr/bin/env bash

. ./setenv.sh

oc project ${OPENSHIFT_PROJECT_NAME}

# Use the CICD templates
oc create -f ../cicd-templates/achievement/achievement-build.json -n ${OPENSHIFT_PROJECT_NAME}
oc create -f ../cicd-templates/achievement/achievement-deploy.json -n ${OPENSHIFT_PROJECT_NAME}
oc create -f ../cicd-templates/achievement/achievement-services.json -n ${OPENSHIFT_PROJECT_NAME}

oc new-app --template=achievement-services  -p HOSTNAME_HTTP=achievement-server.${OPENSHIFT_PROJECT_NAME}
oc new-app --template=achievement-build -p SOURCE_SECRET_NAME=github-summit -p IMAGE_STREAM_NAMESPACE=${OPENSHIFT_PROJECT_NAME}
oc new-app --template=achievement-deployments -p DEPLOYMENT_NAME=achievement -p IMAGE_NAME=${OPENSHIFT_REGISTRY}/demo/achievement -p COLOUR=blue

# Kick-off build
oc start-build achievement

# Load achievement-server template
#oc create -f ../templates/achievement-server.json -n ${OPENSHIFT_PROJECT_NAME}

# Create achievement-server app
#oc new-app --template=achievement-server -p SOURCE_SECRET_NAME=github-summit -p IMAGE_STREAM_NAMESPACE=${OPENSHIFT_PROJECT_NAME} -p HOSTNAME_HTTP=achievement-server.demo
