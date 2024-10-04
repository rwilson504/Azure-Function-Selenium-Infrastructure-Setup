param location string

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: 'selenium-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowFunctionToACI'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '10.0.1.0/24'  // Only allow traffic from function subnet
          destinationAddressPrefix: '10.0.2.0/24'
          sourcePortRange: '*'
          destinationPortRange: '*'
          protocol: '*'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 200
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '10.0.2.0/24'
          sourcePortRange: '*'
          destinationPortRange: '*'
          protocol: '*'
        }
      }
    ]
  }
}

output networkSecurityGroupId string = nsg.id
