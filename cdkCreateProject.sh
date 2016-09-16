#!/usr/bin/env bash

. ./setenv.sh

if [ "$#" -ne 2 ]
then
    echo "You must supply the github username and password as parameters, i.e."
    echo "./cdkCreateProject mygithubusername mygithubpassword"
    echo "These credentials must have access to the Keynote repositories"
    exit 1
fi

export GITHUB_USER=$1
export GITHUB_PW=$2


# Create project
oc new-project ${OPENSHIFT_PROJECT_NAME} --display-name="Summit Game Demo"

# Load template jboss-eap70-openshift, note we load them into project space to keep everything segregated. If you want to change it to OpenShift make sure to update namespace reference in achievement-server.json
oc create -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/jboss-image-streams.json -n ${OPENSHIFT_PROJECT_NAME}

oc project ${OPENSHIFT_PROJECT_NAME}

# Create secret for summit github
echo "Creating github-summit secret for ${GITHUB_USER}"
oc secrets new-basicauth github-summit --username=${GITHUB_USER} --password=${GITHUB_PW}

# Add secret to builder account
oc secrets add serviceaccount/builder secrets/github-summit

# Add role so kubernetes discovery can happen, really need to look at trimming down access instead of giving broad cluster-admin.
# Tried this but no joy: oc policy add-role-to-user system:discovery system:serviceaccount:summit-game:default -n summit-game
oc policy add-role-to-user cluster-admin system:serviceaccount:demo:default -n demo
