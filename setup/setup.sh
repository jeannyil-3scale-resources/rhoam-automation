#!/usr/bin/env bash

. ./env.sh 

oc new-project $DEV_PROJECT 2> /dev/null
while [ $? \> 0 ]; do
    sleep 1
    printf "."
    oc new-project $DEV_PROJECT 2> /dev/null
done

# Create the persistent Jenkins server
oc new-app --template=jenkins-persistent-monitored \
-p VOLUME_CAPACITY=4Gi \
-p MEMORY_LIMIT=2Gi \
-p ENABLE_OAUTH=true

echo "import camel-quarkus-jsonvalidation-api CI/CD pipeline"
oc new-app -f camel-quarkus-jsonvalidation-api/pipeline-app-build.yml \
-p IMAGE_NAMESPACE=$DEV_PROJECT \
-p DEV_PROJECT=$DEV_PROJECT \
-p TEST_PROJECT=$TEST_PROJECT \
-p PROD_PROJECT=$PROD_PROJECT

# echo "import integration-master-pipeline"
# TODO

echo "import 3Scale API publishing pipeline"
oc new-app -f cicd-3scale/3scaletoolbox/pipeline-template.yaml \
-p IMAGE_NAMESPACE=$DEV_PROJECT \
-p DEV_PROJECT=$DEV_PROJECT \
-p TEST_PROJECT=$TEST_PROJECT \
-p PROD_PROJECT=$PROD_PROJECT \
-p PUBLIC_PRODUCTION_WILDCARD_DOMAIN=apps.jeannyil.sandbox438.opentlc.com \
-p PUBLIC_STAGING_WILDCARD_DOMAIN=staging.apps.jeannyil.sandbox438.opentlc.com \
-p DEVELOPER_ACCOUNT_ID=developer

oc new-project $TEST_PROJECT 2> /dev/null
while [ $? \> 0 ]; do
    sleep 1
    printf "."
    oc new-project $TEST_PROJECT 2> /dev/null
done


echo "Setup the surrounding softwate and environment"
echo
echo "Start up MySQL for database access"

oc new-app mysql-ephemeral --param=MYSQL_PASSWORD=password --param=MYSQL_USER=dbuser --param=MYSQL_DATABASE=sampledb --param=MYSQL_VERSION=5.7

echo "Start up Broker"
oc new-app -f projecttemplates/amq-broker-74-basic.yaml --param=AMQ_USER=admin --param=AMQ_PASSWORD=admin

oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:jenkins -n ${TEST_PROJECT}
oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:default -n ${TEST_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${TEST_PROJECT}:default -n ${DEV_PROJECT}
oc policy add-role-to-user view --serviceaccount=default -n ${DEV_PROJECT}

#this should be used in development/demo environment for testing purpose

oc new-project $PROD_PROJECT 2> /dev/null
while [ $? \> 0 ]; do
    sleep 1
    printf "."
    oc new-project $PROD_PROJECT 2> /dev/null
done


echo "Setup the surrounding softwate and environment"
echo
echo "Start up MySQL for database access"
oc project $PROD_PROJECT
oc new-app mysql-ephemeral --param=MYSQL_PASSWORD=password --param=MYSQL_USER=dbuser --param=MYSQL_DATABASE=sampledb --param=MYSQL_VERSION=5.7

echo "Start up Broker"
oc new-app -f projecttemplates/amq-broker-74-basic.yaml --param=AMQ_USER=admin --param=AMQ_PASSWORD=admin


oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:jenkins -n ${PROD_PROJECT}
oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:default -n ${PROD_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${PROD_PROJECT}:default -n ${DEV_PROJECT}
oc policy add-role-to-user view --serviceaccount=default -n ${DEV_PROJECT}

oc project $DEV_PROJECT
