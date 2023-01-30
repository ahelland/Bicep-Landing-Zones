targetScope = 'subscription'

param location string
param env string
@description('Tags retrieved from parameter file.')
param resourceTags object = {}

param adminGroupId string = ''
param k8Sversion string
param vmSize string

resource rg_vnet 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${env}-vnet'
  location: location
  tags: resourceTags
}

resource rg_aks 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${env}-aks'
  location: location
  tags: resourceTags
}

resource rg_acr 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${env}-aks-acr'
  location: location
  tags: resourceTags
}

// "Dummy" vnet module specific for testing AKS. 
// Do not use for generic purposes.
module vnet 'vnet.bicep' = {
  scope: rg_vnet
  name: 'vnet'
  params: {
    name: 'vnet-aks'
    location: location
    snet_01_name: 'snet-aks'
    snet_02_name: 'snet-app'
  }
}

@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param acrName string = 'acr${uniqueString('rg-${env}-aks-acr-wi')}'

@description('Provide a tier of your Azure Container Registry.')
param acrSku string = 'Basic'

module acr 'azure-container-registry.bicep' = {
  scope: rg_acr
  name: acrName
  params: {
    acrName: acrName
    acrSku: acrSku
    location: location
  }
}

module aks 'azure-kubernetes-service.bicep' = {
  scope: rg_aks
  name: 'aks'
  params: {
    location: location
    name: 'dev-aks'
    kubernetesVersion: k8Sversion
    vmSize: vmSize
    snetId: vnet.outputs.snet_01_id
    adminGroupId: adminGroupId
  }
}
