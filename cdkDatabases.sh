#!/usr/bin/env bash

. ./setenv.sh

oc create -f ../templates/game-postgress-ephemeral.json -n demo

oc new-app --template=game-postgresql-ephemeral -p NAMESPACE=demo -p DATABASE_SERVICE_NAME=score-postgresql -p POSTGRESQL_USER=keynote -p POSTGRESQL_PASSWORD=imEffH9QP8QcL -p POSTGRESQL_DATABASE=userdb

oc new-app --template=game-postgresql-ephemeral -p NAMESPACE=demo -p DATABASE_SERVICE_NAME=achievement-postgresql -p POSTGRESQL_USER=keynote -p POSTGRESQL_PASSWORD=imEffH9QP8QcL -p POSTGRESQL_DATABASE=userdb

oc deploy score-postgresql

oc deploy achievement-postgresql
