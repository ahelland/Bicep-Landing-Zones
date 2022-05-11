param location string
param name string

param containerAppEnvironmentId string
param containerImage string

param useExternalIngress bool = false
param containerPort int = 80

param managedIdentity string
//param acrIdentity string

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
      registries: [
        {
          //identity: acrIdentity
          server: registry
          username: registryUsername
          passwordSecretRef: 'container-registry-password'
        }
      ]
      ingress: {
        external: useExternalIngress
        targetPort: containerPort
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
        minReplicas: 0
      }
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
