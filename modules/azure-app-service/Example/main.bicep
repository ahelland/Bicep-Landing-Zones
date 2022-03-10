targetScope = 'subscription'

param location string
param env string
param appName string
param authClientId string = 'placeholder'
@description('Tags retrieved from parameter file.')
param resourceTags object = {}

param easyauthEnabled bool
param aadProviderEnabled bool
param alwaysOn bool
param sku string
param skuCode string
param linuxFxVersion string
param dockerRegistryUrl string
param dockerRegistryUsername string

@secure()
param dockerRegistryPassword string
param dockerRegistryStartupCommand string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${env}-${appName}'
  location: location
  tags: resourceTags
}

module appServicePlan '../app-service-plan.bicep' = {
  scope: rg
  name: 'plan-${appName}'
  params: {
    location: location
    name: appName
    sku: sku
    skuCode: skuCode
  }
}

module appService '../app-service.bicep' = {
  scope: rg
  name: 'app-${appName}'
  params: {
    location: location
    name: appName
    easyauthEnabled: easyauthEnabled
    alwaysOn: alwaysOn
    dockerRegistryPassword: dockerRegistryPassword
    dockerRegistryStartupCommand: dockerRegistryStartupCommand
    dockerRegistryUrl: dockerRegistryUrl
    dockerRegistryUsername: dockerRegistryUsername
    appServicePlanName: appName
    linuxFxVersion: linuxFxVersion
    authClientId: authClientId
    aadProviderEnabled: aadProviderEnabled
  }
  dependsOn:[
    appServicePlan
  ]
}
