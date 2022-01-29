targetScope = 'subscription'

param location string
param env string
param color string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${env}-${color}'
  location: location
}
