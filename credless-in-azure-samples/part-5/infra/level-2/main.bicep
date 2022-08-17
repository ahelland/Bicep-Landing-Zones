targetScope = 'subscription'

param location string
param env string
param appName string
@description('Tags retrieved from parameter file.')
param resourceTags object = {}

param suffix string = uniqueString('rg-${env}-${appName}')

param sku string
param skuCode string

param metadataContainerImage string
param susiGenContainerImage string
param b2csusiAppContainerImage string
param aspEnvironment string
param containerPort int

//For role assignment of managed identity
@description('Key Vault Secrets User role id')
param roleDefinitionId string = '4633458b-17de-408a-b874-0445c86b69e6'
var secretUserRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)

param certificateName string = 'cert-${env}-${appName}'

//For susiGenContainerApp
param authClientId string

//For b2csusiappContainerApp
param AzureAd__Instance string
param AzureAd__Domain string
param AzureAd__TenantId string
param AzureAd__ClientId string

//
param acrName string

resource rg_kv 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${env}-kv-${appName}'
  location: location
  tags: resourceTags
}

resource rg_aca 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${env}-aca-${appName}'
  location: location
  tags: resourceTags
}

resource acr 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' existing = {
  scope: resourceGroup('rg-${env}-acr-${appName}')
  name: acrName
}

@description('Name needs to be less than 24 characters total.')
module keyVault '../../../../modules/azure-key-vault/key-vault.bicep' = {
  scope: rg_kv
  name: 'kv-${env}-${suffix}'
  params: {
    location: location
    name: 'kv-${env}-${suffix}'
    skuCode: skuCode
    sku: sku
  }
}

//Azure Container Apps as runtime platform
module containerAppEnvironment '../modules/container-environment.bicep' = {
  scope: rg_aca
  name: 'container-app-environment'
  params: {
    location: location
    name: appName
  }
}

module metadataContainerApp '../modules/container-app.bicep' = {
  scope: rg_aca
  name: '${appName}-oidc'
  params: {
    managedIdentity: 'SystemAssigned'
    containerAppEnvironmentId: containerAppEnvironment.outputs.id
    containerImage: '${acr.properties.loginServer}/${metadataContainerImage}'
    containerPort: containerPort
    location: location
    name: '${appName}-oidc'
    registry: acr.properties.loginServer
    registryPassword: acr.listCredentials().passwords[0].value
    registryUsername: acr.listCredentials().username
    useExternalIngress: true
    envVars: [
      {
        name: 'ASPNETCORE_ENVIRONMENT'
        value: aspEnvironment
      }
      {
        name: 'AzureAd__Instance'
        value: '${AzureAd__Instance}.b2clogin.com'
      }
      {
        name: 'AzureAd__Domain'
        value: '${AzureAd__Domain}.onmicrosoft.com'
      }
      {
        name: 'JWTSettings__issuer'
        value: 'https://contoso.com'
      }        
      {
        name: 'JWTSettings__SigningCertThumbprint'
        value: kvCert.outputs.certificateThumbprintHex
      }
      {
        name: 'JWTSettings__HostEnvironment'
        value: 'ACA'
      }
      {
        name: 'AzureSettings__KeyVaultName'
        value: keyVault.name
      }
      {
        name: 'AzureSettings__CertificateName'
        value: certificateName
      }
    ]
  }
}

// The token generator is secured with EasyAuth (separate module)
module susiGenContainerApp '../modules/container-app-easyauth.bicep' = {
  scope: rg_aca
  name: '${appName}-susigen'
  params: {    
    authClientId: authClientId        
    managedIdentity: 'SystemAssigned'
    containerAppEnvironmentId: containerAppEnvironment.outputs.id
    containerImage: '${acr.properties.loginServer}/${susiGenContainerImage}'
    containerPort: containerPort
    location: location
    name: '${appName}-susigen'
    registry: acr.properties.loginServer    
    registryPassword: acr.listCredentials().passwords[0].value
    registryUsername: acr.listCredentials().username
    useExternalIngress: true
    envVars: [
      {
        name: 'ASPNETCORE_ENVIRONMENT'
        value: aspEnvironment
      }  
      {
        name: 'JWTSettings__issuer'
        value: 'https://contoso.com'
      }
      {
        name: 'JWTSettings__audience'
        value: 'contosob2c'
      }    
      {
        name: 'JWTSettings__SigningCertThumbprint'
        value: kvCert.outputs.certificateThumbprintHex
      }
      {
        name: 'JWTSettings__HostEnvironment'
        value: 'ACA'
      }
      {
        name: 'AzureSettings__KeyVaultName'
        value: keyVault.name
      }
      {
        name: 'AzureSettings__CertificateName'
        value: certificateName
      }
      {
        name: 'SuSiSettings__B2CSignInUrlBase'
        value: 'https://${b2csusiappContainerApp.outputs.fqdn}'
      }
      {
        name: 'SuSiSettings__B2CSignUpUrlBase'
        value: 'https://${b2csusiappContainerApp.outputs.fqdn}'
      }
      {
        name: 'SuSiSettings__B2CSignInPolicy'
        value: 'B2C_1A_SIGNIN_LINK_GITHUB'
      }
      {
        name: 'SuSiSettings__B2CSignUpPolicy'
        value: 'B2C_1A_INVITATION_LINK_GITHUB'
      }
    ]
  }      
}

module b2csusiappContainerApp '../modules/container-app.bicep' = {
  scope: rg_aca
  name: '${appName}-b2csusiapp'
  params: {
    managedIdentity: 'SystemAssigned'
    containerAppEnvironmentId: containerAppEnvironment.outputs.id    
    containerImage: '${acr.properties.loginServer}/${b2csusiAppContainerImage}'
    containerPort: containerPort
    location: location
    name: '${appName}-b2csusiapp'
    registry: acr.properties.loginServer    
    registryPassword: acr.listCredentials().passwords[0].value
    registryUsername: acr.listCredentials().username
    useExternalIngress: true
    envVars: [
      {
        name: 'ASPNETCORE_ENVIRONMENT'
        value: aspEnvironment
      }  
      {
        name: 'AzureAd__Instance'
        value: '${AzureAd__Instance}.b2clogin.com'
      }
      {
        name: 'AzureAd__Domain'
        value: '${AzureAd__Domain}.onmicrosoft.com'
      }
      {
        name: 'AzureAd__TenantId'
        value: AzureAd__TenantId
      }
      {
        name: 'AzureAd__ClientId'
        value: AzureAd__ClientId
      }
      {
        name: 'AzureAd__SignUpSignInPolicyId'
        value: 'B2C_1A_SIGNUP_SIGNIN_GITHUB'
      }
    ]
  }
}

// Cert
module kvCert 'br/public:deployment-scripts/create-kv-certificate:1.1.1' = {
  scope: rg_kv
  name: 'akvCertSingle'
  params: {
    akvName: keyVault.name
    location: location
    certificateName: certificateName
  }
}

//Oh, the pain - https://github.com/Azure/bicep/issues/2031
module metadataKvRole 'roleAssignment.bicep' = { 
  scope: resourceGroup('rg-${env}-kv-${appName}')
  name: guid('${keyVault.name}-metadata')
  params: {   
    keyVaultName: keyVault.name 
    name: guid('${keyVault.name}-metadata')
    principalId: metadataContainerApp.outputs.managedIdentityPrincipal
    roleDefinitionId: secretUserRole
  }
}

module susigenKvRole 'roleAssignment.bicep' = { 
  scope: resourceGroup('rg-${env}-kv-${appName}')
  name: guid('${keyVault.name}-susigen')
  params: {   
    keyVaultName: keyVault.name 
    name: guid('${keyVault.name}-susigen')
    principalId: susiGenContainerApp.outputs.managedIdentityPrincipal
    roleDefinitionId: secretUserRole
  }
}

output b2capp_url string    = b2csusiappContainerApp.outputs.fqdn
output oidc_metadata string = metadataContainerApp.outputs.fqdn
output susigen_url string   = susiGenContainerApp.outputs.fqdn
