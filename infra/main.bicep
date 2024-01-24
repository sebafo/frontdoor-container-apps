@description('Azure Location/Region')
param location_primary_region string = resourceGroup().location

param location_secondary_region string = 'northeurope'

@description('Tags')
param tags object = {  
  Environment: 'dev'  
  TechnicalOwner: 'owner@owner.com'
}

@description('Basename / Prefix of all resources')
@minLength(4)
@maxLength(12)
param baseName string

module network_primary_region './modules/network.bicep' = {
  name: 'network_primary_region'
  params: {    
    location: location_primary_region
    tags: tags
    baseName: baseName
  }
}

module network_secondary_region './modules/network.bicep' = {
  name: 'network_secondary_region'
  params: {    
    location: location_secondary_region
    tags: tags
    baseName: baseName
  }
}

module logAnalytics './modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    location: location_primary_region
    tags: tags
    baseName: baseName
  }
}

module containerAppsEnv_primary_region './modules/containerAppsEnv.bicep' = {
  name: 'containerapps_primary_region'
  params: {
    location: location_primary_region
    tags: tags
    baseName: baseName
    logAnalyticsWorkspaceName: logAnalytics.outputs.logAnalyticsWorkspaceName
    infrastructureSubnetId: network_primary_region.outputs.containerappsSubnetid
  }
}

module containerApp_primary_region './modules/containerApp.bicep' = {
  name: 'containerApp_primary_region'
  params: {
    location: location_primary_region
    tags: tags
    baseName: baseName
    containerAppsEnvironmentId: containerAppsEnv_primary_region.outputs.containerAppsEnvironmentId
    containerImage: 'sebafo/containerapp:v1'
  }
}

module containerAppsEnv_secondary_region './modules/containerAppsEnv.bicep' = {
  name: 'containerapps_secondary_region'
  params: {
    location: location_secondary_region
    tags: tags
    baseName: baseName
    logAnalyticsWorkspaceName: logAnalytics.outputs.logAnalyticsWorkspaceName
    infrastructureSubnetId: network_secondary_region.outputs.containerappsSubnetid
  }
}

module containerApp_secondary_region './modules/containerApp.bicep' = {
  name: 'containerApp_secondary_region'
  params: {
    location: location_secondary_region
    tags: tags
    baseName: baseName
    containerAppsEnvironmentId: containerAppsEnv_secondary_region.outputs.containerAppsEnvironmentId
    containerImage: 'sebafo/containerapp:v1'
  }
}

module privateLinkService_primary_region './modules/privateLinkService.bicep' = {
  name: 'privatelink_primary_region'
  params: {
    location: location_primary_region
    tags: tags
    baseName: baseName
    vnetSubnetId: network_primary_region.outputs.containerappsSubnetid
    containerAppsDefaultDomainName: containerAppsEnv_primary_region.outputs.containerAppsEnvironmentDefaultDomain
  }
}

module privateLinkService_secondary_region './modules/privateLinkService.bicep' = {
  name: 'privatelink_secondary_region'
  params: {
    location: location_secondary_region
    tags: tags
    baseName: baseName
    vnetSubnetId: network_secondary_region.outputs.containerappsSubnetid
    containerAppsDefaultDomainName: containerAppsEnv_secondary_region.outputs.containerAppsEnvironmentDefaultDomain
  }
}

module frontDoor './modules/frontdoor.bicep' = {
  name: 'frontdoor'
  params: {
    baseName: baseName
    location_primary: location_primary_region
    location_secondary: location_secondary_region
    tags: tags
    privateLinkServiceId_primary: privateLinkService_primary_region.outputs.privateLinkServiceId
    privateLinkServiceId_secondary: privateLinkService_secondary_region.outputs.privateLinkServiceId
    frontDoorAppHostName_primary: containerApp_primary_region.outputs.containerFqdn
    frontDoorAppHostName_secondary: containerApp_secondary_region.outputs.containerFqdn
  }
}

// Re-Read Private Link Service to get Pending Approval status
module readPrivateLinkService './modules/readPrivateEndpoint.bicep' = {
  name: 'readprivatelink'
  params: {
    privateLinkServiceName: privateLinkService_primary_region.outputs.privateLinkServiceName
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
  privateLinkServiceId: privateLinkService_primary_region.outputs.privateLinkServiceId
  privateLinkEndpointConnectionId: privateLinkEndpointConnectionId
}
