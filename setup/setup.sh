#!/usr/bin/env bash

. ./env.sh 

##### START: Set up DEV Project #####

oc new-project $DEV_PROJECT 2> /dev/null
while [ $? \> 0 ]; do
    sleep 1
    printf "."
    oc new-project $DEV_PROJECT 2> /dev/null
done

# /!\ Create the persistent Jenkins instance

# - Using an OpenShift template
oc new-app --template=jenkins-persistent \
-p VOLUME_CAPACITY=4Gi \
-p MEMORY_LIMIT=2Gi \
-p ENABLE_OAUTH=true

# - Using the Jenkins Operator
# /!\ Install the Jenkins Operator in the DEV project through OLM
## Create the namespace OperatorGroup (the Jenkins operator is singleNamespace-scoped)
# oc create --save-config -f setup/rh-dev-operatorgroup.yaml

## The _Jenkins Operator_ subscription
# oc create --save-config -f setup/openshift-jenkins-operator-subscription.yaml

## Wait for Jenkins Operator to be installed
# watch oc get sub,csv,installPlan

## Create the Jenkins instance:
# oc create --save-config -f setup/jenkins-persistent_cr.yaml

# /!\ If Jenkins Instance is installed using the OpenShift template
oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:jenkins -n ${DEV_PROJECT}
# /!\ If Jenkins Instance is installed using the  Jenkins Operator
# oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:jenkins-persistent -n ${DEV_PROJECT}

echo "import camel-quarkus-jsonvalidation-api CI/CD build pipeline"
oc new-app -f cicd-api-build/camel-quarkus-jsonvalidation-api/camel-quarkus-jsonvalidation-api_build-deploy-pipeline.yml \
-p IMAGE_NAMESPACE=$DEV_PROJECT \
-p DEV_PROJECT=$DEV_PROJECT \
-p TEST_PROJECT=$TEST_PROJECT \
-p PROD_PROJECT=$PROD_PROJECT

# echo "import integration-master-pipeline"
# TODO

echo "import camel-quarkus-jsonvalidation-api 3Scale API publishing pipeline"
oc new-app -f cicd-3scale/3scaletoolbox/camel-quarkus-jsonvalidation-api/camel-quarkus-jsonvalidation-api_pipeline-template.yaml \
-p GIT_REPO="https://github.com/jeannyil-rhoam-resources/rhoam-automation.git" \
-p GIT_BRANCH="main" \
-p IMAGE_NAMESPACE=$DEV_PROJECT \
-p DEV_PROJECT=$DEV_PROJECT \
-p TEST_PROJECT=$TEST_PROJECT \
-p PROD_PROJECT=$PROD_PROJECT \
-p TARGET_INSTANCE=3scale-rhpds \
-p PUBLIC_PRODUCTION_WILDCARD_DOMAIN=apps.jeannyil.sandbox1148.opentlc.com \
-p PUBLIC_STAGING_WILDCARD_DOMAIN=staging.apps.jeannyil.sandbox1148.opentlc.com \
-p OIDC_ISSUER_ENDPOINT="https://client_id:client_secret@sso.apps.jeannyil.sandbox1148.opentlc.com/auth/realms/RH3scaleAdminPortal" \
-p DEVELOPER_ACCOUNT_ID=3 \
-p BASIC_PLAN_YAML_FILE_PATH="https://raw.githubusercontent.com/jeannyil-rhoam-resources/rhoam-automation/main/cicd-3scale/3scaletoolbox/camel-quarkus-jsonvalidation-api/camel-quarkus-jsonvalidation-api_basic-plan.yaml" \
-p UNLIMITED_PLAN_YAML_FILE_PATH="https://raw.githubusercontent.com/jeannyil-rhoam-resources/rhoam-automation/main/cicd-3scale/3scaletoolbox/camel-quarkus-jsonvalidation-api/camel-quarkus-jsonvalidation-api_unlimited-plan.yaml" \
-p DISABLE_TLS_VALIDATION="no" \
-p TOOLBOX_IMAGE_REGISTRY="image-registry.openshift-image-registry.svc:5000/rh-dev/toolbox-rhel7:3scale2.10"

##### END: Set up DEV Project #####

##### START: Set up Test Project #####

oc new-project $TEST_PROJECT 2> /dev/null
while [ $? \> 0 ]; do
    sleep 1
    printf "."
    oc new-project $TEST_PROJECT 2> /dev/null
done

oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:default -n ${TEST_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${TEST_PROJECT}:default -n ${DEV_PROJECT}
oc policy add-role-to-user view --serviceaccount=default -n ${DEV_PROJECT}
# /!\ If Jenkins Instance is installed using the OpenShift template
oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:jenkins -n ${TEST_PROJECT}
# \!\ If Jenkins Instance is installed using the  Jenkins Operator
# oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:jenkins-persistent -n ${TEST_PROJECT}

##### END: Set up Test Project #####

#this should be used in development/demo environment for testing purpose

##### START: Set up PROD Project #####

oc new-project $PROD_PROJECT 2> /dev/null
while [ $? \> 0 ]; do
    sleep 1
    printf "."
    oc new-project $PROD_PROJECT 2> /dev/null
done

oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:default -n ${PROD_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${PROD_PROJECT}:default -n ${DEV_PROJECT}
oc policy add-role-to-user view --serviceaccount=default -n ${DEV_PROJECT}
# /!\ If Jenkins Instance is installed using the OpenShift template
oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:jenkins -n ${PROD_PROJECT}
# /!\ If Jenkins Instance is installed using the  Jenkins Operator
# oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:jenkins-persistent -n ${PROD_PROJECT}

##### END: Set up PROD Project #####

# Set context to the DEV OpenShift project
oc project $DEV_PROJECT
