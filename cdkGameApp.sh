#!/usr/bin/env bash

. ./setenv.sh

oc project ${OPENSHIFT_PROJECT_NAME}

oc create -f ../templates/game-app.json -n ${OPENSHIFT_PROJECT_NAME}

oc new-app --template=game-app-template -p SOURCE_SECRET_NAME=github-summit -p IMAGE_STREAM_NAMESPACE=${OPENSHIFT_PROJECT_NAME}
