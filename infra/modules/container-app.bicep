param location string
param name string
param managedEnvironmentId string
param containerRegistryName string
param identityId string
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
param environmentVariables array = []
param secrets array = []
param tags object = {}

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
        identityId
      ]
    }
    registries: [
      {
        server: '${containerRegistryName}.azurecr.io'
        identity: identityId
      }
    ]
    scaleSettings: {
      minReplicas: 1
      maxReplicas: 1
    }
    secrets: secrets
  }
}

output name string = app.outputs.name
output fqdn string = app.outputs.fqdn
output id string = app.outputs.resourceId

