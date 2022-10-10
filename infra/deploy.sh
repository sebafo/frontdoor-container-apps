#!/bin/sh
set -e

echo "Deployment started..."

BASE_NAME="<<< TBD >>>"
LOCATION="northeurope"
RESOURCE_GROUP_NAME=$BASE_NAME-rg
DEPLOYMENT_NAME=$BASE_NAME-deployment-$(date +%s)

az group create \
    --name $RESOURCE_GROUP_NAME \
    --location $LOCATION

RESULT=$(az deployment group create \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $DEPLOYMENT_NAME \
    --template-file main.bicep \
    --parameters baseName=$BASE_NAME \
    --query properties.outputs.result)

PRIVATE_LINK_ENDPOINT_CONNECTION_ID=$(echo $RESULT | jq -r '.value.privateLinkEndpointConnectionId')
FQDN=$(echo $RESULT | jq -r '.value.fqdn')
PRIVATE_LINK_SERVICE_ID=$(echo $RESULT | jq -r '.value.privateLinkServiceId')

# if [ -z "$PRIVATE_LINK_ENDPOINT_CONNECTION_ID" ]; then
#     echo "Failed to get privateLinkEndpointConnectionId"
#     while [ -z "$PRIVATE_LINK_ENDPOINT_CONNECTION_ID" ]; do
#         echo "- retrying..."
#         PRIVATE_LINK_ENDPOINT_CONNECTION_ID=$(az network private-endpoint-connection list --id $PRIVATE_LINK_SERVICE_ID --query "[0].id" -o tsv)
#         sleep 5
#     done
# fi
echo "Private link endpoint connection ID: $PRIVATE_LINK_ENDPOINT_CONNECTION_ID"
az network private-endpoint-connection approve --id $PRIVATE_LINK_ENDPOINT_CONNECTION_ID

echo "...Deployment FINISHED!"
echo "Please wait a few minutes until endpoint is established..."
echo "--- FrontDoor FQDN: https://$FQDN ---"