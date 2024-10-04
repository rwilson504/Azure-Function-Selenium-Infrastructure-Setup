param location string = resourceGroup().location
param functionAppName string = 'mySeleniumFunctionApp'
param appServicePlanName string = 'myAppServicePlan'
param storageAccountName string = 'mystorageacct${uniqueString(resourceGroup().id)}'
param seleniumImage string = 'selenium/standalone-edge'
param seleniumImageTag string = 'latest'
param clientId string
param keyVaultName string = 'myKeyVault'
@secure()
param clientSecret string

// Deploy the Storage Account
module storageAccountModule 'storage.bicep' = {
  name: 'storageAccountDeployment'
  params: {
    location: location
    storageAccountName: storageAccountName
  }
}

// Deploy the Network Security Group
module networkSecurityGroupModule 'networkSecurityGroup.bicep' = {
  name: 'networkSecurityGroupDeployment'
  params: {
    location: location
  }
}

// Deploy the Virtual Network
module virtualNetworkModule 'virtualNetwork.bicep' = {
  name: 'virtualNetworkDeployment'
  params: {
    location: location
    networkSecurityGroupId: networkSecurityGroupModule.outputs.networkSecurityGroupId
  }
}

// Deploy the App Service Plan
module appServicePlanModule 'appServicePlan.bicep' = {
  name: 'appServicePlanDeployment'
  params: {
    location: location
    appServicePlanName: appServicePlanName
  }
}

// Deploy the Selenium ACI (Azure Container Instance)
module seleniumAciModule 'seleniumACI.bicep' = {
  name: 'seleniumAciDeployment'
  params: {
    location: location
    containerName: '${functionAppName}-selenium'
    seleniumImage: seleniumImage
    seleniumImageTag: seleniumImageTag
    //dnsNameLabel: '${functionAppName}-selenium-dns'
    subnetId: virtualNetworkModule.outputs.aciSubnetId
  }
}

// Deploy Application Insights
module appInsightsModule 'appInsights.bicep' = {
  name: 'appInsightsDeployment'
  params: {
    location: location
    functionAppName: functionAppName
  }
}

// Deploy the Function App
module functionAppModule 'functionApp.bicep' = {
  name: 'functionAppDeployment'
  params: {
    location: location
    functionAppName: functionAppName
    appServicePlanId: appServicePlanModule.outputs.appServicePlanId
    storageAccountId: storageAccountModule.outputs.storageAccountId
    storageAccountName: storageAccountModule.outputs.storageAccountName
    appInsightsInstrumentationKey: appInsightsModule.outputs.appInsightsInstrumentationKey
    appInsightsConnectionString: appInsightsModule.outputs.appInsightsConnectionString
    seleniumAciPublicIP: seleniumAciModule.outputs.seleniumAciPublicIP
    clientId: clientId
    keyVaultName: keyVaultName
    subnetId: virtualNetworkModule.outputs.functionSubnetId
  }
}

// Deploy the Key Vault
module keyVaultModule 'keyVault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    location: location
    keyVaultName: keyVaultName
    clientSecret: clientSecret
    functionAppPrincipalId: functionAppModule.outputs.functionAppPrincipalId
  }
}

// Output the Function App's hostname
output functionAppDefaultHostName string = functionAppModule.outputs.functionAppDefaultHostName
