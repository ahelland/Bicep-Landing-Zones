param location string
param name string

@description('Tags retrieved from parameter file.')
param resourceTags object = {}

param dockerRegistryUrl string
param dockerRegistryUsername string
param dockerRegistryPassword string
param linuxFxVersion string
param dockerRegistryStartupCommand string
param alwaysOn bool
param serverFarmResourceGroup string = resourceGroup().name
param subscriptionId string = subscription().id
param tenantId string = tenant().tenantId
param appServicePlanName string
param easyauthEnabled bool
param aadProviderEnabled bool
param aadEndpoint string
param authClientId string
param managedIdentity string
@secure()
param authClientSecret string

resource appservice 'Microsoft.Web/sites@2021-03-01' = {
  name: name
  location: location
  tags: resourceTags
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: dockerRegistryUrl
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: dockerRegistryUsername
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: dockerRegistryPassword
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
          value: authClientSecret
        }
      ]
      linuxFxVersion: linuxFxVersion
      appCommandLine: dockerRegistryStartupCommand
      alwaysOn: alwaysOn
      http20Enabled: true
    }    
    serverFarmId: '/subscriptions/${subscriptionId}/resourcegroups/${serverFarmResourceGroup}/providers/Microsoft.Web/serverfarms/${appServicePlanName}'
    clientAffinityEnabled: false
    httpsOnly: true    
  }
  identity: {
    type: managedIdentity
  }
  dependsOn: []
  
  resource easyauth_config 'config' = {
    name: 'authsettingsV2'    
    properties: {
      httpSettings: {
        requireHttps: true
      }
      globalValidation: {
        requireAuthentication: true
        redirectToProvider: 'azureActiveDirectory'
        unauthenticatedClientAction: 'RedirectToLoginPage'
      }
      platform: {
        enabled: easyauthEnabled
      }
      login: {
        tokenStore: {
          enabled: true
        }
      }
      identityProviders: {
        azureActiveDirectory: {
          enabled: aadProviderEnabled
          registration: {
            clientId: authClientId
            openIdIssuer: 'https://${aadEndpoint}/${tenantId}/v2.0/'
            clientSecretSettingName: 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
          }
          login: {
            loginParameters: [
            'response_type=code id_token'
            'scope=openid offline_access profile https://graph.microsoft.com/User.Read'
            ]
          }   
        }
      }
    }
  }
}

