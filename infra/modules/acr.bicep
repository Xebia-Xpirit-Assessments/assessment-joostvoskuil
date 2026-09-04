param location string
param name string
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

output id string = registry.outputs.resourceId
output name string = registry.outputs.name
output loginServer string = registry.outputs.loginServer
