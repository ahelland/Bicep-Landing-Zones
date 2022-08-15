param name string
param principalId string
param roleDefinitionId string
param keyVaultName string

resource keyvault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}

resource roleAssigment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: name
  scope: keyvault
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinitionId
  }
}
