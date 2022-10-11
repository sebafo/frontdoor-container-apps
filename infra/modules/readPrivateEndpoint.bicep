@description('Name of the Private Link Service')
param privateLinkServiceName string

// Read Private Link Service
resource privateLinkService 'Microsoft.Network/privateLinkServices@2022-01-01' existing = {
  name: privateLinkServiceName
}

var privateLinkEndpointConnectionId = length(privateLinkService.properties.privateEndpointConnections) > 0 ? filter(privateLinkService.properties.privateEndpointConnections, (connection) => connection.properties.privateLinkServiceConnectionState.description == 'frontdoor')[0].id : ''
output privateLinkEndpointConnectionId string = privateLinkEndpointConnectionId
