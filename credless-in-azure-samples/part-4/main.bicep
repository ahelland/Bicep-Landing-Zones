targetScope = 'subscription'

param location string
param env string
@description('Tags retrieved from parameter file.')
param resourceTags object = {}

// Dummy value for verification purposes
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

// Using the Bicep public module registry
// https://github.com/Azure/bicep-registry-modules
module aks_vnet 'br/public:network/virtual-network:1.0.1' = {
  scope: rg_vnet
  name: 'aks-${env}-vnet'
  params: {
    location: location
    name: 'vnet-aks'
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    subnets: [
      {
        name: 'snet-01'
        addressPrefix: '10.0.0.0/24'
      }
      {
        name: 'snet-02'
        addressPrefix: '10.0.1.0/24'
      }
    ]
  }
}

module aks '../../modules/azure-kubernetes-service/aks.bicep' = {
  scope: rg_aks
  name: 'aks'
  params: {
    location: location
    name: '${env}-aks'
    kubernetesVersion: k8Sversion
    vmSize: vmSize    
    snetId: aks_vnet.outputs.subnetResourceIds[0]
    adminGroupId: adminGroupId
  }
}

@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param acrName string = 'acr${uniqueString('rg-${env}-aks-acr')}'

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
