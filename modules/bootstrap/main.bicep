//Based on:
//https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-bicep?tabs=CLI

targetScope = 'subscription'

@description('Provide a location for the registry.')
param location string
param env string
@description('Tags retrieved from parameter file.')
param resourceTags object = {}

param rgName string = 'rg-${env}-bicep-acr'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
  tags: resourceTags
}

@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param acrName string = 'acr${uniqueString(rgName)}'

@description('Provide a tier of your Azure Container Registry.')
param acrSku string = 'Basic'

module acr 'azure-container-registry.bicep' = {
  scope: rg
  name: acrName
  params: {
    acrName: acrName
    acrSku: acrSku
    location: location
  }
}

output acr_url string = acr.outputs.loginServer
