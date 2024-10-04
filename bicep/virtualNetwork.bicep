param location string
param networkSecurityGroupId string

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: 'selenium-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
      
    }    
    subnets: [
      {
        name: 'function-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroupId  // Associate NSG to the Function App subnet
          }
          delegations: [  // Add the required delegation for Azure Function App
            {
              name: 'functionDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }        
      }
      {
        name: 'aci-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroupId  // Associate NSG to the ACI subnet
          }
          delegations: [  // Add the required delegation for Container Instances
            {
              name: 'aciDelegation'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
    ]
  }
}

output functionSubnetId string = vnet.properties.subnets[0].id
output aciSubnetId string = vnet.properties.subnets[1].id
