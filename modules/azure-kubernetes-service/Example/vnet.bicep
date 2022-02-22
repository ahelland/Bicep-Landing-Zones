param name string
param location string
param snet_01_name string
param snet_02_name string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: snet_01_name
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: snet_02_name
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }

  resource snet_01 'subnets' existing = {
    name: snet_01_name
  }

  resource snet_02 'subnets' existing = {
    name: snet_02_name
  }
}

output snet_01_id string = virtualNetwork::snet_01.id
output snet_02_id string = virtualNetwork::snet_02.id
