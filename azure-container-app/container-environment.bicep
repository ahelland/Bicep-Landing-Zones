param name string
param location string

//Include Log Analytics in module to avoid passing clientSecret as output
resource loganalytics 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: 'log-analytics-${name}'
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource containerenvironment 'Microsoft.Web/kubeEnvironments@2021-02-01' = {
  name: 'container-environment-${name}'
  location: location
  properties: {
    type: 'Managed'
    internalLoadBalancerEnabled: false
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: loganalytics.properties.customerId
        sharedKey: loganalytics.listKeys().primarySharedKey
      }
    }
  }
}

output id string = containerenvironment.id
