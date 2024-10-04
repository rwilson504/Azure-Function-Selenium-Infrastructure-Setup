param location string
param appServicePlanName string

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'P1v2'  
    tier: 'Premium'
    capacity: 1
  }
  kind: 'functionapp'
  properties: {
    reserved: false  
  }
}

output appServicePlanId string = appServicePlan.id
