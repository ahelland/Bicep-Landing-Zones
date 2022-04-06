param location string
param name string

@description('Tags retrieved from parameter file.')
param resourceTags object = {}

param tenantId string = tenant().tenantId

param sku string
param skuCode string

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: name
  location: location
  tags: resourceTags
  properties: {
    sku: {
      family: skuCode
      name: sku
    }
    tenantId: tenantId
    enableRbacAuthorization: true
  }
}
