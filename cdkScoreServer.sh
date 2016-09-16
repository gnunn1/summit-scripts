#!/usr/bin/env bash

. ./setenv.sh

oc project ${OPENSHIFT_PROJECT_NAME}

# Use the CICD templates
oc create -f ../cicd-templates/score/score-build.json -n ${OPENSHIFT_PROJECT_NAME}
oc create -f ../cicd-templates/score/score-deploy.json -n ${OPENSHIFT_PROJECT_NAME}
oc create -f ../cicd-templates/score/score-services.json -n ${OPENSHIFT_PROJECT_NAME}

oc new-app --template=score-services  -p APPLICATION_NAME=score -p HOSTNAME_HTTP=score-server.${OPENSHIFT_PROJECT_NAME}
oc new-app --template=score-build -p APPLICATION_NAME=score -p SOURCE_SECRET_NAME=github-summit -p IMAGE_STREAM_NAMESPACE=${OPENSHIFT_PROJECT_NAME} -p SOURCE_REPOSITORY_URL=https://github.com/gnunn1/score-server -p SOURCE_REPOSITORY_REF=master
oc new-app --template=score-deployments -p APPLICATION_NAME=score -p DEPLOYMENT_NAME=score -p IMAGE_NAME=${OPENSHIFT_REGISTRY}/demo/score -p COLOUR=blue

# Kick-off build
oc start-build score

# Load score-server template
#oc create -f ../templates/score-server.json -n ${OPENSHIFT_PROJECT_NAME}

# Create score-server app
#oc new-app --template=decisionserver62-basic-s2i -p SOURCE_SECRET_NAME=github-summit -p SOURCE_REPOSITORY_URL=https://github.com/gnunn1/score-server -p SOURCE_REPOSITORY_REF=master -p IMAGE_STREAM_NAMESPACE=${OPENSHIFT_PROJECT_NAME} -p KIE_SERVER_PASSWORD=ki3server! -p HOSTNAME_HTTP=score-server.demo
