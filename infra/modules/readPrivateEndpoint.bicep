@description('Name of the Private Link Service')
param privateLinkServiceName string

// Read Private Link Service
resource privateLinkService 'Microsoft.Network/privateLinkServices@2022-01-01' existing = {
  name: privateLinkServiceName
}

output privateLinkEndpointConnectionId string = length(privateLinkService.properties.privateEndpointConnections) > 0 ? privateLinkService.properties.privateEndpointConnections[0].id : ''
