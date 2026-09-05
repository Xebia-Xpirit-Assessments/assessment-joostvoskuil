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

@description('CAF-compliant shared Azure Container Registry name. ACR names are globally unique and alphanumeric only.')
param containerRegistryName string

@description('Resource group that owns the shared Azure Container Registry.')
param containerRegistryResourceGroupName string

@description('PostgreSQL administrator login.')
param postgresAdministratorLogin string = 'eshopadmin'

@secure()
@description('PostgreSQL administrator password. Supply through a GitHub Environment secret.')
param postgresAdministratorPassword string

@secure()
@description('RabbitMQ application password. Supply through a GitHub Environment secret.')
param rabbitMqPassword string

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

module rabbitMqAcrPull './modules/acr-pull-assignment.bicep' = {
  name: 'rabbitmqAcrPull'
  scope: resourceGroup(containerRegistryResourceGroupName)
  params: {
    containerRegistryName: containerRegistryName
    principalId: rabbitMq.outputs.identityPrincipalId
  }
}
output resourceGroupName string = rg.name
output containerAppsEnvironmentName string = environmentName
output containerRegistryName string = containerRegistryName
