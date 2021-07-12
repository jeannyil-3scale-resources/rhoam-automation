# 3scale Publish API with 3scale Toolbox

## Setup

1. Install [3scale toolbox](https://github.com/3scale/3scale_toolbox_packaging).

2. Configure/Add remote with 3scale URL and token by using 3scale toolbox command as seen below

    ```zsh
    3scale remote add 3scale-tenant https://$TOKEN@$TENANT_ADMIN_PORTAL_HOSTNAME/
    ```

3. Create the Secret in openshift project.

    ```zsh
    oc project rh-dev

    oc create secret generic 3scale-toolbox \
    --from-file=$HOME/.3scalerc.yaml
    ```

4. Read the following:

    - [Installing the 3scale Toolbox supported by Red Hat](https://access.redhat.com/documentation/en-us/red_hat_3scale_api_management/2.10/html/operating_3scale/the-threescale-toolbox#installing-the-toolbox)
    - [3scale-toolbox Configuration](https://access.redhat.com/documentation/en-us/red_hat_3scale_api_management/2.10/html/operating_3scale/api-lifecyle-toolbox-3scale#api-lifecycle-install-toolbox-3scale)

5. Download the 3scaletoolbox image and push it your OpenShift registry:

    - **RECOMMENDED** - you can use the image version supported by Red Hat from [Red Hat Containers Catalog](https://catalog.redhat.com/software/containers/3scale-amp2/toolbox-rhel7/5d80bbe95a13461f5f050cf7)

      1. Create a docker-registry secret with the credentials to authenticate on the Red Hat Container registry
          ```zsh
          oc create secret docker-registry redhat-registry-auth \
          --docker-server=registry.redhat.io \
          --docker-username='REGISTRY-SERVICE-ACCOUNT-USERNAME' \
          --docker-password='REGISTRY-SERVICE-ACCOUNT-PASSWORD'
          ```
      2. Import the 3scale Toolbox image in the DEV OpenShift project:
          ```zsh
          oc import-image 3scale-amp2/toolbox-rhel7:3scale2.9 \
          --from=registry.redhat.io/3scale-amp2/toolbox-rhel7:3scale2.9 \
          --confirm
          ```
    - **OR** - you can use image version from [quay.io](https://quay.io/repository/redhat/3scale-toolbox?tag=v0.18.2&tab=tags)

        ```zsh
          oc import-image redhat/3scale-toolbox:v0.18.2 \
          --from=quay.io/redhat/3scale-toolbox:v0.18.2 \
          --confirm
        ```

6. view [3scale-toolbox Jenkinsfile for camel-quarkus-jsonvalidation-api](./3scaletoolbox/camel-quarkus-jsonvalidation-api/camel-quarkus-jsonvalidation-api_Jenkinsfile)

7. Create pipeline, update the pipeline parameters as per your environment .

    ```zsh
    oc new-app -f ./cicd-3scale/3scaletoolbox/camel-quarkus-jsonvalidation-api/camel-quarkus-jsonvalidation-api_pipeline-template.yaml  \
    -p IMAGE_NAMESPACE=rh-dev \
    -p DEV_PROJECT=rh-dev \
    -p TEST_PROJECT=rh-test \
    -p PROD_PROJECT=rh-prod \
    -p PRIVATE_BASE_URL=<API_URL> \
    -p PUBLIC_PRODUCTION_WILDCARD_DOMAIN=<WILDCARD_DOMAIN> \
    -p PUBLIC_STAGING_WILDCARD_DOMAIN=staging.<WILDCARD_DOMAIN> \
    -p OIDC_ISSUER_ENDPOINT=https://<CLIENT_ID>:<CLIENT_SECRET>@<HOST>:<PORT>/auth/realms/<REALM_NAME> \
    -p DEVELOPER_ACCOUNT_ID=developer
    ```