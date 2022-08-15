param location string
param name string

param containerAppEnvironmentId string
param containerImage string

param useExternalIngress bool = false
param containerPort int = 80

param managedIdentity string
param authClientId string

param registry string
param registryUsername string = ''
@secure()
param registryPassword string = ''

param envVars array = []

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: name
  location: location

  identity: {
    type: managedIdentity
  }

  properties: { 
    managedEnvironmentId: containerAppEnvironmentId
    configuration: {
      secrets: [
        {
          name: 'container-registry-password'
          value: registryPassword
        }
      ]
      registries: [ {
          server: registry
          username: registryUsername
          passwordSecretRef: 'container-registry-password'
        } ]
      ingress: {
        external: useExternalIngress
        targetPort: containerPort
        transport: 'http'
      }
    }
    template: {
      containers: [
        {
          image: containerImage
          name: name
          env: envVars
        }
      ]
      scale: {
        // Bug with Blazor and Websockets with ACA so force max 1
        minReplicas: 0
        maxReplicas: 1
      }
    }
  }
  
  resource easyauth_config 'authConfigs' = {
    name: 'current'        
    properties: {
      httpSettings: {
        requireHttps: true
      }
      globalValidation: {        
        redirectToProvider: 'azureactivedirectory'
        unauthenticatedClientAction: 'RedirectToLoginPage'
      }
      platform: {
        enabled: true
      }
      
      identityProviders: {
        azureActiveDirectory: {
          enabled: true
          registration: {
            clientId: authClientId  
            clientSecretSettingName: ''          
          }
          validation: {
            allowedAudiences: []
          }           
        }
      }

      login: {
        preserveUrlFragmentsForLogins: true
      }
    }
  }
  
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
output managedIdentityPrincipal string = containerApp.identity.principalId
