targetScope = 'subscription'

@description('Azure region for the shared artifact registry.')
param location string

@description('CAF-compliant resource group that owns shared delivery artifacts.')
param resourceGroupName string = 'rg-eshop-shared-swe-001'

@description('CAF-compliant Azure Container Registry name. ACR names are globally unique and alphanumeric only.')
@minLength(5)
@maxLength(50)
param containerRegistryName string = 'acreshopsharedswe001'

@description('Object ID of the GitHub Actions service principal permitted to publish signed images.')
param imagePublisherPrincipalId string

var tags = {
  application: 'eshop'
  environment: 'shared'
  managedBy: 'bicep'
  purpose: 'signed-artifacts'
  workload: 'eshop'
}

resource sharedResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module registry './modules/acr.bicep' = {
  name: 'sharedContainerRegistry'
  scope: resourceGroup(sharedResourceGroup.name)
  params: {
    location: location
    name: containerRegistryName
    deploymentPrincipalId: imagePublisherPrincipalId
    tags: tags
  }
}

output containerRegistryName string = registry.outputs.name
output containerRegistryLoginServer string = registry.outputs.loginServer
output resourceGroupName string = sharedResourceGroup.name
