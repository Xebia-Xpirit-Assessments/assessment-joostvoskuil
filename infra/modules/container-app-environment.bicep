param location string
param name string
param logAnalyticsWorkspaceName string
param tags object = {}

module workspace 'br/public:avm/res/operational-insights/workspace:0.12.0' = {
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    tags: tags
    dataRetention: 30
    enableTelemetry: false
    skuName: 'PerGB2018'
  }
}

module environment 'br/public:avm/res/app/managed-environment:0.16.0' = {
  params: {
    name: name
    location: location
    tags: tags
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsWorkspaceResourceId: workspace.outputs.resourceId
    }
    enableTelemetry: false
    publicNetworkAccess: 'Enabled'
    zoneRedundant: false
  }
}

output id string = environment.outputs.resourceId
output defaultDomain string = environment.outputs.defaultDomain
