param location string
param name string
param managedEnvironmentId string
param containerRegistryName string
param image string
param containerPort int = 8080
param externalIngress bool = false
@allowed([
  'auto'
  'http'
  'http2'
  'tcp'
])
param ingressTransport string = 'auto'
@minValue(0)
param minReplicas int = 1
@minValue(1)
param maxReplicas int = 1
param scaleRules array = []
param probes array = []
param environmentVariables array = []
param secrets array = []
param tags object = {}

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${name}'
  location: location
  tags: tags
}

resource acrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(registry.id, identity.id, 'AcrPull')
  scope: registry
  properties: {
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}

module app 'br/public:avm/res/app/container-app:0.23.0' = {
  params: {
    name: name
    location: location
    tags: tags
    containers: [
      {
        name: 'app'
        image: image
        resources: {
          cpu: json('0.25')
          memory: '0.5Gi'
        }
        env: environmentVariables
        probes: probes
      }
    ]
    environmentResourceId: managedEnvironmentId
    enableTelemetry: false
    ingressAllowInsecure: false
    ingressExternal: externalIngress
    ingressTargetPort: containerPort
    ingressTransport: ingressTransport
    managedIdentities: {
      userAssignedResourceIds: [
        identity.id
      ]
    }
    registries: [
      {
        server: registry.properties.loginServer
        identity: identity.id
      }
    ]
    scaleSettings: {
      minReplicas: minReplicas
      maxReplicas: maxReplicas
      rules: scaleRules
    }
    secrets: secrets
  }
  dependsOn: [
    acrPull
  ]
}

output name string = app.outputs.name
output fqdn string = app.outputs.fqdn
output id string = app.outputs.resourceId
