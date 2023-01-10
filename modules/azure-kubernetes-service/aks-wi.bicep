param name string
param location string
param snetId string
param kubernetesVersion string
param vmSize string
param adminGroupId string

resource aks_identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'aks-identity'
  location: location
}

// Docs: 
// https://docs.microsoft.com/en-us/azure/templates/microsoft.containerservice/managedclusters?tabs=bicep
resource aks_cluster 'Microsoft.ContainerService/managedClusters@2022-09-02-preview' = {
  name: name
  location: location

  sku: {
    name: 'Basic'
    tier: 'Free'
  }
  
  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    aadProfile: {
      adminGroupObjectIDs: [
        adminGroupId
      ]
      enableAzureRBAC: true
      managed: true      
    }

    agentPoolProfiles: [
      {
        count: 1        
        maxPods: 100
        
        mode: 'System'
        name: 'nodepool01'
        
        orchestratorVersion: kubernetesVersion
        osDiskSizeGB: 30
        osType: 'Linux'
        
        tags: {}
        
        vmSize: vmSize
        vnetSubnetID: snetId
      }
    ]
    
    autoUpgradeProfile: {
      upgradeChannel: 'node-image'
    }
    disableLocalAccounts: true
    dnsPrefix: 'aks'
    enableRBAC: true
    kubernetesVersion: kubernetesVersion  
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: 'azure'
      networkPolicy: 'calico'
      serviceCidr: '172.16.0.0/16'
      dnsServiceIP: '172.16.0.10'
    }

    //Used for workload identity
    oidcIssuerProfile: {
      enabled: true
    }
    
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }

    publicNetworkAccess: 'Enabled'  
  }
}
