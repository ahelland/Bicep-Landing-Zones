targetScope = 'subscription'

param location string
param env string
param appName string
param keyVaultName string
@description('Tags retrieved from parameter file.')
param resourceTags object = {}

param suffix string = uniqueString(subscription().id)

param easyauthEnabled bool
param aadProviderEnabled bool
param authClientId string = 'placeholder'
param aadEndpoint string
param alwaysOn bool
param sku string
param skuCode string
param linuxFxVersion string
param dockerRegistryUrl string
param dockerRegistryUsername string
param managedIdentity string = 'SystemAssigned'

//For role assignment of managed identity
param roleDefinitionId string = '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User role id
var secretUserRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)

@secure()
param dockerRegistryPassword string
param dockerRegistryStartupCommand string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${env}-${appName}'
  location: location
  tags: resourceTags
}

module appServicePlan '../../../../modules/azure-app-service/app-service-plan.bicep' = {
  scope: rg
  name: 'plan-${env}-${appName}'
  params: {
    location: location
    name: 'plan-${env}-${appName}'
    sku: sku
    skuCode: skuCode
  }
}

module appService '../../../../modules/azure-app-service/app-service.bicep' = {
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
    authClientSecret: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=authClientSecret)'
    aadEndpoint: aadEndpoint
    aadProviderEnabled: aadProviderEnabled
    managedIdentity: managedIdentity
  }
  
  dependsOn:[
    appServicePlan
  ]
}

//Oh, the pain - https://github.com/Azure/bicep/issues/2031
module myRole 'roleAssignment.bicep' = { 
  scope: resourceGroup('rg-${env}-kv-${appName}')
  name: guid(keyVaultName)
  params: {   
    keyVaultName: keyVaultName 
    name: guid(keyVaultName)
    principalId: appService.outputs.managedIdentityPrincipal
    roleDefinitionId: secretUserRole
  }
}
