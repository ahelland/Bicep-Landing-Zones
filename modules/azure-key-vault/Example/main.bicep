targetScope = 'subscription'

param location string
param env string
param appName string

@description('Tags retrieved from parameter file.')
param resourceTags object = {}
@description('Used for constructing a unique name.')
param suffix string = uniqueString(appName)
param sku string
param skuCode string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${env}-kv-${appName}'
  location: location
  tags: resourceTags
}

@description('Name needs to be less than 24 characters total.')
module keyVault '../key-vault.bicep' = {
  scope: rg
  name: 'kv-${env}-${suffix}'
  params: {
    location: location
    name: 'kv-${env}-${suffix}'
    skuCode: skuCode
    sku: sku
  }
}
