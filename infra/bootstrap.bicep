targetScope = 'subscription'

@description('Azure region for the environment resources.')
param location string

@description('CAF-compliant resource group name, supplied by the deployment workflow.')
param resourceGroupName string

@description('CAF-compliant Azure Container Registry name. ACR names are globally unique and alphanumeric only.')
@minLength(5)
@maxLength(50)
param containerRegistryName string

@description('Common tags applied to bootstrap resources.')
param tags object = {}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module registry './modules/acr.bicep' = {
  name: 'containerRegistry'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: containerRegistryName
    tags: tags
  }
}

output resourceGroupName string = rg.name
output containerRegistryName string = registry.outputs.name
output containerRegistryLoginServer string = registry.outputs.loginServer
