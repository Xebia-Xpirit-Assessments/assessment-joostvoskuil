param location string
param name string
param deploymentPrincipalId string
param tags object = {}

module registry 'br/public:avm/res/container-registry/registry:0.13.0' = {
  params: {
    name: name
    location: location
    tags: tags
    acrAdminUserEnabled: false
    acrSku: 'Standard'
    enableTelemetry: false
    networkRuleBypassOptions: 'AzureServices'
    networkRuleSetDefaultAction: 'Allow'
    publicNetworkAccess: 'Enabled'
    quarantinePolicyStatus: 'disabled'
    retentionPolicyDays: 7
    retentionPolicyStatus: 'enabled'
    trustPolicyStatus: 'disabled'
  }
}

resource registryResource 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: name
}

resource deploymentAcrPush 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(name, deploymentPrincipalId, 'AcrPush')
  scope: registryResource
  properties: {
    principalId: deploymentPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8311e382-0749-4cb8-b61a-304f252e45ec')
  }
}

output id string = registry.outputs.resourceId
output name string = registry.outputs.name
output loginServer string = registry.outputs.loginServer
