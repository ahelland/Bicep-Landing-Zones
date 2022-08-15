param location string
param acrName string
param acrSku string
param adminUserEnabled bool
param anonymousPullEnabled bool
param managedIdentity string

resource acrResource 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: acrName
  location: location
  identity: {
    type: managedIdentity
  }
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    anonymousPullEnabled: anonymousPullEnabled
  }
}

@description('Output the login server property for later use')
output loginServer string = acrResource.properties.loginServer

// Managed identity for ACA doesn't support registry pulls yet
output admin string = acrResource.listCredentials().username
output password string = acrResource.listCredentials().passwords[0].value
