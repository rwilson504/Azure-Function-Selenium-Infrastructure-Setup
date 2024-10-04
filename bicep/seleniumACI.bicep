param location string
param containerName string = 'selenium-edge-container'
param seleniumImage string = 'selenium/standalone-edge'
param seleniumImageTag string = 'latest'
param cpuCores int = 2
param memoryInGb int = 4
param containerPort int = 4444
//param dnsNameLabel string
param subnetId string

resource seleniumACI 'Microsoft.ContainerInstance/containerGroups@2021-07-01' = {
  name: containerName
  location: location
  properties: {
    containers: [
      {
        name: containerName
        properties: {
          image: '${seleniumImage}:${seleniumImageTag}'
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
            }
          }
          ports: [
            {
              port: containerPort
            }
          ]
        }
      }
    ]
    subnetIds:[
      {id: subnetId}
    ]
    osType: 'Linux'
    restartPolicy: 'OnFailure'
    ipAddress: {
      type: 'Private'
      //dnsNameLabel: dnsNameLabel
      ports: [
        {
          protocol: 'TCP'
          port: containerPort
        }
      ]
    }
    // ipAddress: {
    //   type: 'Private'  // Ensure that the ACI gets a private IP
    //   ports: [
    //     {
    //       protocol: 'TCP'
    //       port: 4444
    //     }
    //   ]
    // }
    // networkProfile: {
    //   id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'selenium-vnet', 'aci-subnet')  // Associate with ACI subnet
    // }
  }
}

output seleniumAciPublicIP string = seleniumACI.properties.ipAddress.ip
