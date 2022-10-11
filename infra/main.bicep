@description('Azure Location/Region')
param location string = resourceGroup().location

@description('Basename / Prefix of all resources')
@minLength(4)
@maxLength(12)
param baseName string

module network './modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    baseName: baseName
  }
}

module logAnalytics './modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    location: location
    baseName: baseName
  }
}

module containerAppsEnv './modules/containerAppsEnv.bicep' = {
  name: 'containerapps'
  params: {
    location: location
    baseName: baseName
    logAnalyticsWorkspaceName: logAnalytics.outputs.logAnalyticsWorkspaceName
    infrastructureSubnetId: network.outputs.containerappsSubnetid
  }
}

module containerApp './modules/containerApp.bicep' = {
  name: 'containerApp'
  params: {
    location: location
    baseName: baseName
    containerAppsEnvironmentId: containerAppsEnv.outputs.containerAppsEnvironmentId
    containerImage: 'sebafo/containerapp:v1'
  }
}

module privateLinkService './modules/privateLinkService.bicep' = {
  name: 'privatelink'
  params: {
    location: location
    baseName: baseName
    vnetSubnetId: network.outputs.containerappsSubnetid
    containerAppsDefaultDomainName: containerAppsEnv.outputs.containerAppsEnvironmentDefaultDomain
  }
}

module frontDoor './modules/frontdoor.bicep' = {
  name: 'frontdoor'
  params: {
    baseName: baseName
    location: location
    privateLinkServiceId: privateLinkService.outputs.privateLinkServiceId
    frontDoorAppHostName: containerApp.outputs.containerFqdn
  }
}

// Re-Read Private Link Service to get Pending Approval status
module readPrivateLinkService './modules/readPrivateEndpoint.bicep' = {
  name: 'readprivatelink'
  params: {
    privateLinkServiceName: privateLinkService.outputs.privateLinkServiceName
  }

  dependsOn: [
    frontDoor
  ]
}

// Prepare Output
var privateLinkEndpointConnectionId = readPrivateLinkService.outputs.privateLinkEndpointConnectionId
var fqdn = frontDoor.outputs.fqdn

// Outputs
output frontdoor_fqdn string = fqdn
output privateLinkEndpointConnectionId string = privateLinkEndpointConnectionId

output result object = {
  fqdn: fqdn
  privateLinkServiceId: privateLinkService.outputs.privateLinkServiceId
  privateLinkEndpointConnectionId: privateLinkEndpointConnectionId
}
