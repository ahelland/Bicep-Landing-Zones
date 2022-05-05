param location string
param name string
param containerAppEnvironmentId string

param containerImage string

param useExternalIngress bool = false
param containerPort int = 80

param registry string
param registryUsername string = ''
@secure()
param registryPassword string = ''

param envVars array = []

resource containerApp 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: name  
  location: location
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
