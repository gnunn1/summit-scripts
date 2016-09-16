#!/usr/bin/env bash

. ./setenv.sh

# Add game server template
# oc create -f ../templates/game-server.json -n ${OPENSHIFT_PROJECT_NAME}

# Create new app, app must have vertx-cluster=true label and KUBERNETES_NAMESPACE = project name
#oc new-app --template=vertx-template -p SOURCE_SECRET_NAME=github-summit -p IMAGE_STREAM_NAMESPACE=${OPENSHIFT_PROJECT_NAME} -p APP_OPTIONS=-cluster -p APPLICATION_HOSTNAME=gamebus-production.apps-test.redhatkeynote.com -l vertx-cluster=true

# Use the CICD templates
oc create -f ../cicd-templates/gamebus/gamebus-build.json -n ${OPENSHIFT_PROJECT_NAME}
oc create -f ../cicd-templates/gamebus/gamebus-deploy.json -n ${OPENSHIFT_PROJECT_NAME}
oc create -f ../cicd-templates/gamebus/gamebus-services.json -n ${OPENSHIFT_PROJECT_NAME}

# Create the app
oc new-app --template=gamebus-services  -p HOSTNAME_HTTP=gamebus-production.apps-test.redhatkeynote.com -p HOSTNAME_BOARDS_HTTP=gamebus-boards-production.apps-test.redhatkeynote.com
oc new-app --template=gamebus-build -p SOURCE_SECRET_NAME=github-summit -p IMAGE_STREAM_NAMESPACE=${OPENSHIFT_PROJECT_NAME}
oc new-app --template=gamebus-deployments -p DEPLOYMENT_NAME=gamebus -p IMAGE_NAME=${OPENSHIFT_REGISTRY}/demo/gamebus -p COLOUR=blue -p STAGE=demo -p BUILD_ID=1  -l vertx-cluster=true

# Kick off build
oc start-build gamebus
