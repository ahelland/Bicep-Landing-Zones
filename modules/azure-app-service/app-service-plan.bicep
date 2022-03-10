param location string
param name string

@description('Tags retrieved from parameter file.')
param resourceTags object = {}

param sku string
param skuCode string

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: name
  location: location
  kind: 'linux'
  tags: resourceTags
  properties: {
    reserved: true
    zoneRedundant: false
  }
  sku: {
    tier: sku
    name: skuCode
  }
  dependsOn: []
}
