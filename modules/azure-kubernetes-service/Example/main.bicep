targetScope = 'subscription'

param location string
param env string
@description('Tags retrieved from parameter file.')
param resourceTags object = {}

// Dummy value since this only verifies the module
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

module aks '../aks.bicep' = {
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
