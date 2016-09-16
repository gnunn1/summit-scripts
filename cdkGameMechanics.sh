#!/usr/bin/env bash

. ./setenv.sh

oc project ${OPENSHIFT_PROJECT_NAME}

# Load Fuse Integration Templates
oc create -f https://raw.githubusercontent.com/jboss-fuse/application-templates/master/fis-image-streams.json -n ${OPENSHIFT_PROJECT_NAME}

# Load game-mechanics template
#oc create -f ../templates/game-mechanics.json -n ${OPENSHIFT_PROJECT_NAME}

# Create game-mechanics app
#oc new-app --template=game-mechanics-template -p SOURCE_SECRET_NAME=github-summit -p IMAGE_STREAM_NAMESPACE=${OPENSHIFT_PROJECT_NAME} -p APPLICATION_HOSTNAME=game-mechanics.${OPENSHIFT_PROJECT_NAME}


# Use the CICD templates
oc create -f ../cicd-templates/mechanics/mechanics-build.json -n ${OPENSHIFT_PROJECT_NAME}
oc create -f ../cicd-templates/mechanics/mechanics-deploy.json -n ${OPENSHIFT_PROJECT_NAME}
oc create -f ../cicd-templates/mechanics/mechanics-services.json -n ${OPENSHIFT_PROJECT_NAME}

# Create the app
oc new-app --template=mechanics-services  -p HOSTNAME_HTTP=game-mechanics.${OPENSHIFT_PROJECT_NAME}
oc new-app --template=mechanics-build -p APPLICATION_NAME=mechanics  -p SOURCE_SECRET_NAME=github-summit -p IMAGE_STREAM_NAMESPACE=${OPENSHIFT_PROJECT_NAME}
oc new-app --template=mechanics-deployments -p DEPLOYMENT_NAME=mechanics -p IMAGE_NAME=${OPENSHIFT_REGISTRY}/demo/mechanics -p COLOUR=blue

# Kick off build
oc start-build mechanics
