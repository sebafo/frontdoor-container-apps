@description('Basename / Prefix of all resources')
param baseName string

@description('Azure Location/Region')
param location_primary string 

@description('Azure Location/Region')
param location_secondary string 

@description('Tags')
param tags object

@description('Private Link Service Id')
param privateLinkServiceId_primary string

@description('Private Link Service Id')
param privateLinkServiceId_secondary string

@description('Hostname of App - Primary')
param frontDoorAppHostName_primary string

@description('Hostname of App - Primary')
param frontDoorAppHostName_secondary string

// Define names
var frontDoorProfileName = '${baseName}-fd'
var frontDoorEndpointName = '${baseName}-fd-endpoint'
var frontDoorOriginGroupName = '${baseName}-fd-og'
var frontDoorOriginRouteName = '${baseName}-fd-route'
var frontDoorOriginName_primary = '${baseName}-fd-origin-primary'
var frontDoorOriginName_secondary = '${baseName}-fd-origin-secondary'


resource frontDoorProfile 'Microsoft.Cdn/profiles@2022-05-01-preview' = {
  name: frontDoorProfileName
  location: 'Global'
  tags: tags
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    originResponseTimeoutSeconds: 120
    extendedProperties: {}
  }
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdendpoints@2022-05-01-preview' = {
  parent: frontDoorProfile
  name: frontDoorEndpointName
  location: 'Global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/origingroups@2022-05-01-preview' = {
  parent: frontDoorProfile
  name: frontDoorOriginGroupName
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/health'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: 'Disabled'
  }
}

resource frontDoorOrigin_primary 'Microsoft.Cdn/profiles/origingroups/origins@2022-05-01-preview' = {
  parent: frontDoorOriginGroup
  name: frontDoorOriginName_primary
  properties: {
    hostName: frontDoorAppHostName_primary
    httpPort: 80
    httpsPort: 443
    originHostHeader: frontDoorAppHostName_primary
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    sharedPrivateLinkResource: {
      privateLink: {
        id: privateLinkServiceId_primary
      }
      privateLinkLocation: location_primary
      requestMessage: 'frontdoor'
    }
    enforceCertificateNameCheck: true
  }
}

resource frontDoorOrigin_secondary 'Microsoft.Cdn/profiles/origingroups/origins@2022-05-01-preview' = {
  parent: frontDoorOriginGroup
  name: frontDoorOriginName_secondary
  properties: {
    hostName: frontDoorAppHostName_secondary
    httpPort: 80
    httpsPort: 443
    originHostHeader: frontDoorAppHostName_secondary
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    sharedPrivateLinkResource: {
      privateLink: {
        id: privateLinkServiceId_secondary
      }
      privateLinkLocation: location_secondary
      requestMessage: 'frontdoor'
    }
    enforceCertificateNameCheck: true
  }
}

resource frontDoorOriginRoute 'Microsoft.Cdn/profiles/afdendpoints/routes@2022-05-01-preview' = {
  parent: frontDoorEndpoint
  name: frontDoorOriginRouteName
  properties: {
    originGroup: {
      id: frontDoorOriginGroup.id
    }
    originPath: '/'
    ruleSets: []
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
  }

  dependsOn: [
    frontDoorOrigin_primary
    frontDoorOrigin_secondary
  ]
}

output fqdn string = frontDoorEndpoint.properties.hostName
