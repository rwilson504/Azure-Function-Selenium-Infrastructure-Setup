param location string
param functionAppPrincipalId string
param keyVaultName string
@secure()
param clientSecret string

// Create the Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    enableRbacAuthorization: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    publicNetworkAccess: 'Enabled'
  }
}

// Store the client secret in Key Vault
resource secret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  parent: keyVault
  name: 'aad-client-secret'  // Name of the secret in Key Vault
  properties: {
    value: clientSecret  // Store the client secret securely
  }
}

var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

// Grant RBAC access to the Function App's Managed Identity using Key Vault Secrets User role
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(keyVault.id, functionAppPrincipalId, keyVaultSecretsUserRoleId)  // Key Vault Secrets User role
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)  // Key Vault Secrets User role
    principalId: functionAppPrincipalId  // The Managed Identity of the Function App
    principalType: 'ServicePrincipal'
  }
}
