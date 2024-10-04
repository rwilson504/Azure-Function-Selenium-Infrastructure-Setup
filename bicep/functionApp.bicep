param location string
param functionAppName string
param appServicePlanId string
param storageAccountId string
param storageAccountName string
param appInsightsInstrumentationKey string
param appInsightsConnectionString string
param seleniumAciPublicIP string
param clientId string
param keyVaultName string
param subnetId string

// Function App definition
resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    virtualNetworkSubnetId: subnetId  // Connect to VNet
    siteConfig: {
      netFrameworkVersion: 'v8.0'
      appSettings: [
        {
          name: 'FUNCTIONS_INPROC_NET8_ENABLED'
          value: '1'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'AzureWebJobsStorage__blobServiceUri'
          value: 'https://${storageAccountName}.blob.${environment().suffixes.storage}'
        }
        {
          name: 'AzureWebJobsStorage__fileServiceUri'
          value: 'https://${storageAccountName}.file.${environment().suffixes.storage}'
        }
        {
          name: 'AzureWebJobsStorage__queueServiceUri'
          value: 'https://${storageAccountName}.queue.${environment().suffixes.storage}'
        }
        {
          name: 'AzureWebJobsStorage__tableServiceUri'
          value: 'https://${storageAccountName}.table.${environment().suffixes.storage}'
        }
        // Use Key Vault Reference for the Client Secret
        {
          name: 'AAD_CLIENT_SECRET'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}${environment().suffixes.keyvaultDns}/secrets/aad-client-secret)' // Key Vault reference for the client secret
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'Selenium_Grid_Url'
          value: 'http://${seleniumAciPublicIP}:4444'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ]
    }
  }
}

// Authentication (authSettingsV2) configuration for the Function App
resource functionAppAuthSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: functionApp
  name: 'authsettingsV2'
  properties: {
    platform: {
      enabled: true // Enable Authentication/Authorization
    }
    globalValidation: {
      redirectToProvider: 'azureactivedirectory' // Redirect to Azure AD for authentication
      requireAuthentication: true // Require Authentication for all requests
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true // Enable Azure AD Authentication
        registration: {
          clientId: clientId // Use the AAD App Registration Client ID
          openIdIssuer: '${environment().authentication.loginEndpoint}/${tenant().tenantId}/v2.0' // Dynamically generate the OpenID Connect issuer URL
          clientSecretSettingName: 'AAD_CLIENT_SECRET'
        }
        validation: {
          allowedAudiences: [
            'api://${clientId}' // Allowed audience for the Function App
          ]
        }
      }
    }
    login: { 
      tokenStore: { 
        enabled: true 
      } 
    }
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, resourceGroup().id, storageAccountId, 'Storage Blob Data Contributor')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
    ) // Storage Blob Data Owner role
    principalId: functionApp.identity.principalId
  }
}

output functionAppDefaultHostName string = functionApp.properties.defaultHostName
output functionAppPrincipalId string = functionApp.identity.principalId
