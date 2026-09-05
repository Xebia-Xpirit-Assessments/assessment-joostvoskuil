targetScope = 'subscription'

@description('Azure region, for example swedencentral.')
param location string

@description('CAF-compliant resource group name, supplied by the deployment workflow.')
param resourceGroupName string

@allowed([
  'stg'
  'prd'
])
@description('CAF environment abbreviation.')
param environment string

@description('CAF workload name.')
param workloadName string = 'eshop'

@description('CAF region abbreviation.')
param regionCode string = 'swe'

@description('CAF instance number.')
param instance string = '001'

@description('CAF-compliant Azure Container Registry name. ACR names are globally unique and alphanumeric only.')
@minLength(5)
@maxLength(50)
param containerRegistryName string

@description('Object ID of the GitHub Actions deployment service principal that publishes images to ACR.')
param deploymentPrincipalId string

@description('PostgreSQL administrator login.')
param postgresAdministratorLogin string = 'eshopadmin'

@secure()
@description('PostgreSQL administrator password. Supply through a GitHub Environment secret.')
param postgresAdministratorPassword string

@secure()
@description('RabbitMQ application password. Supply through a GitHub Environment secret.')
param rabbitMqPassword string

@minValue(0)
param rabbitMqMinReplicas int = 1
@minValue(1)
param rabbitMqMaxReplicas int = 1
param rabbitMqScaleRules array = []

var nameSuffix = '${workloadName}-${environment}-${regionCode}-${instance}'
var environmentName = 'cae-${nameSuffix}'
var workspaceName = 'log-${nameSuffix}'
var postgresName = 'psql-${nameSuffix}'
var redisName = 'redis-${nameSuffix}'
var rabbitMqName = 'ca-${workloadName}-rabbitmq-${environment}-${regionCode}-${instance}'
var tags = {
  application: workloadName
  environment: environment
  managedBy: 'bicep'
  workload: workloadName
}

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
    deploymentPrincipalId: deploymentPrincipalId
    tags: tags
  }
}

module containerAppsEnvironment './modules/container-app-environment.bicep' = {
  name: 'containerAppsEnvironment'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: environmentName
    logAnalyticsWorkspaceName: workspaceName
    tags: tags
  }
}

module postgres './modules/postgres.bicep' = {
  name: 'postgres'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: postgresName
    administratorLogin: postgresAdministratorLogin
    administratorPassword: postgresAdministratorPassword
    tags: tags
  }
}

module redis './modules/redis.bicep' = {
  name: 'redis'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: redisName
    tags: tags
  }
}

module rabbitMq './modules/container-app.bicep' = {
  name: 'rabbitMq'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: rabbitMqName
    managedEnvironmentId: containerAppsEnvironment.outputs.id
    containerRegistryName: containerRegistryName
    image: 'rabbitmq:3.13-management'
    containerPort: 5672
    ingressTransport: 'tcp'
    minReplicas: rabbitMqMinReplicas
    maxReplicas: rabbitMqMaxReplicas
    scaleRules: rabbitMqScaleRules
    probes: [
      {
        type: 'Startup'
        tcpSocket: {
          port: 5672
        }
        initialDelaySeconds: 10
        periodSeconds: 10
        timeoutSeconds: 5
        failureThreshold: 30
      }
      {
        type: 'Liveness'
        tcpSocket: {
          port: 5672
        }
        initialDelaySeconds: 10
        periodSeconds: 10
        timeoutSeconds: 5
        failureThreshold: 3
      }
      {
        type: 'Readiness'
        tcpSocket: {
          port: 5672
        }
        initialDelaySeconds: 10
        periodSeconds: 10
        timeoutSeconds: 5
        failureThreshold: 3
      }
    ]
    environmentVariables: [
      {
        name: 'RABBITMQ_DEFAULT_USER'
        value: 'eshop'
      }
      {
        name: 'RABBITMQ_DEFAULT_PASS'
        secretRef: 'rabbitmq-password'
      }
    ]
    secrets: [
      {
        name: 'rabbitmq-password'
        value: rabbitMqPassword
      }
    ]
    tags: tags
  }
}
output resourceGroupName string = rg.name
output containerAppsEnvironmentName string = environmentName
output containerRegistryName string = registry.outputs.name
output containerRegistryLoginServer string = registry.outputs.loginServer
