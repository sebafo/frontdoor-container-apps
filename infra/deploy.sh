#!/bin/sh
set -e

######################################
## Define Variables _ UPDATE VALUES
BASE_NAME="rg-containers-infra"
LOCATION="uksouth"
######################################

## Resource Group & Deployment
RESOURCE_GROUP_NAME=$BASE_NAME-rg
DEPLOYMENT_NAME=$BASE_NAME-deployment-$(date +%s)

## Register Providers
az provider register --wait --namespace Microsoft.App
az provider register --wait --namespace Microsoft.ContainerService
az provider register --wait --namespace Microsoft.Cdn

## Create Resource Group
az group create \
    --name $RESOURCE_GROUP_NAME \
    --location $LOCATION

## Deploy Template
RESULT=$(az deployment group create \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $DEPLOYMENT_NAME \
    --template-file main.bicep \
    --parameters baseName=$BASE_NAME \
    --query properties.outputs.result)

## Output Result
PRIVATE_LINK_ENDPOINT_CONNECTION_ID=$(echo $RESULT | jq -r '.value.privateLinkEndpointConnectionId')
FQDN=$(echo $RESULT | jq -r '.value.fqdn')
PRIVATE_LINK_SERVICE_ID=$(echo $RESULT | jq -r '.value.privateLinkServiceId')

# FALLBACK: Private Link Service approval
# if [ -z "$PRIVATE_LINK_ENDPOINT_CONNECTION_ID" ]; then
#     echo "Failed to get privateLinkEndpointConnectionId"
#     while [ -z "$PRIVATE_LINK_ENDPOINT_CONNECTION_ID" ]; do
#         echo "- retrying..."
#         PRIVATE_LINK_ENDPOINT_CONNECTION_ID=$(az network private-endpoint-connection list --id $PRIVATE_LINK_SERVICE_ID --query "[0].id" -o tsv)
#         sleep 5
#     done
# fi

## Approve Private Link Service
echo "Private link endpoint connection ID: $PRIVATE_LINK_ENDPOINT_CONNECTION_ID"
az network private-endpoint-connection approve --id $PRIVATE_LINK_ENDPOINT_CONNECTION_ID --description "(Frontdoor) Approved by CI/CD"

echo "...Deployment FINISHED!"
echo "Please wait a few minutes until endpoint is established..."
echo "--- FrontDoor FQDN: https://$FQDN ---"