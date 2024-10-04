param location string
param storageAccountName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: false  // Disable shared access keys (SAS tokens)
  }
}

output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
