targetScope = 'subscription'

param location string
param env string
param appName string
@description('Tags retrieved from parameter file.')
param resourceTags object = {}
param acrManagedIdentity string = 'None'

resource rg_acr 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${env}-acr-${appName}'
  location: location
  tags: resourceTags
}

// ACR for images
@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param acrName string = 'acr${uniqueString('rg-${env}-aks-acr')}'

@description('Provide a tier of your Azure Container Registry.')
param acrSku string

module acr '../container-registry.bicep' = {
  scope: rg_acr
  name: acrName
  params: {
    acrName: acrName
    acrSku: acrSku
    location: location
    adminUserEnabled: true
    anonymousPullEnabled: false
    managedIdentity: acrManagedIdentity
  }
}
