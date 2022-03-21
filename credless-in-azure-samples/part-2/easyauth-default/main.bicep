targetScope = 'subscription'

param location string
param env string
param appName string
param authClientId string = 'placeholder'
@secure()
param authClientSecret string
@description('Tags retrieved from parameter file.')
param resourceTags object = {}

param suffix string = uniqueString(subscription().id)

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

module appServicePlan '../../../modules/azure-app-service/app-service-plan.bicep' = {
  scope: rg
  name: 'plan-${env}-${appName}'
  params: {
    location: location
    name: 'plan-${env}-${appName}'
    sku: sku
    skuCode: skuCode
  }
}

module appService '../../../modules/azure-app-service/app-service.bicep' = {
  scope: rg
  name: 'app-${env}-${appName}-${suffix}'
  params: {
    location: location
    name: 'app-${env}-${appName}-${suffix}'
    easyauthEnabled: easyauthEnabled
    alwaysOn: alwaysOn
    dockerRegistryPassword: dockerRegistryPassword
    dockerRegistryStartupCommand: dockerRegistryStartupCommand
    dockerRegistryUrl: dockerRegistryUrl
    dockerRegistryUsername: dockerRegistryUsername
    appServicePlanName: 'plan-${env}-${appName}'
    linuxFxVersion: linuxFxVersion
    authClientId: authClientId
    authClientSecret: authClientSecret
    aadProviderEnabled: aadProviderEnabled
  }
  dependsOn:[
    appServicePlan
  ]
}
