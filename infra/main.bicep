targetScope = 'resourceGroup'

@description('Azure region, for example swedencentral.')
param location string

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

@description('The environment-specific ACR name created by bootstrap.bicep.')
param containerRegistryName string

@description('Immutable image tag, normally the Git commit SHA.')
param imageTag string

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
var identityName = 'ca-${workloadName}-identity-${environment}-${regionCode}-${instance}'
var basketName = 'ca-${workloadName}-basket-${environment}-${regionCode}-${instance}'
var catalogName = 'ca-${workloadName}-catalog-${environment}-${regionCode}-${instance}'
var orderingName = 'ca-${workloadName}-ordering-${environment}-${regionCode}-${instance}'
var webName = 'ca-${workloadName}-web-${environment}-${regionCode}-${instance}'
var tags = {
  application: workloadName
  environment: environment
  managedBy: 'bicep'
  workload: workloadName
}

module containerAppsEnvironment './modules/container-app-environment.bicep' = {
  name: 'containerAppsEnvironment'
  params: {
    location: location
    name: environmentName
    logAnalyticsWorkspaceName: workspaceName
    tags: tags
  }
}

module postgres './modules/postgres.bicep' = {
  name: 'postgres'
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
  params: {
    location: location
    name: redisName
    tags: tags
  }
}

var rabbitMqConnectionString = 'amqp://eshop:${uriComponent(rabbitMqPassword)}@${rabbitMqName}.internal.${containerAppsEnvironment.outputs.defaultDomain}:5672'
var catalogConnectionString = 'Host=${postgres.outputs.fullyQualifiedDomainName};Port=5432;Database=catalogdb;Username=${postgresAdministratorLogin};Password=${postgresAdministratorPassword};Ssl Mode=Require;Trust Server Certificate=true'
var identityConnectionString = 'Host=${postgres.outputs.fullyQualifiedDomainName};Port=5432;Database=identitydb;Username=${postgresAdministratorLogin};Password=${postgresAdministratorPassword};Ssl Mode=Require;Trust Server Certificate=true'
var orderingConnectionString = 'Host=${postgres.outputs.fullyQualifiedDomainName};Port=5432;Database=orderingdb;Username=${postgresAdministratorLogin};Password=${postgresAdministratorPassword};Ssl Mode=Require;Trust Server Certificate=true'
var redisConnectionString = redis.outputs.primaryStackExchangeRedisConnectionString
var identityUrl = 'https://${identityName}.${containerAppsEnvironment.outputs.defaultDomain}'
var webAppUrl = 'https://${webName}.${containerAppsEnvironment.outputs.defaultDomain}'

module rabbitMq './modules/container-app.bicep' = {
  name: 'rabbitMq'
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

module identity './modules/container-app.bicep' = {
  name: 'identity'
  params: {
    location: location
    name: identityName
    managedEnvironmentId: containerAppsEnvironment.outputs.id
    containerRegistryName: containerRegistryName
    image: '${containerRegistryName}.azurecr.io/identity-api:${imageTag}'
    externalIngress: true
    environmentVariables: [
      {
        name: 'ConnectionStrings__identitydb'
        secretRef: 'identitydb'
      }
      {
        name: 'WebAppClient'
        value: webAppUrl
      }
    ]
    secrets: [
      {
        name: 'identitydb'
        value: identityConnectionString
      }
    ]
    tags: tags
  }
}

module basket './modules/container-app.bicep' = {
  name: 'basket'
  params: {
    location: location
    name: basketName
    managedEnvironmentId: containerAppsEnvironment.outputs.id
    containerRegistryName: containerRegistryName
    image: '${containerRegistryName}.azurecr.io/basket-api:${imageTag}'
    ingressTransport: 'http2'
    environmentVariables: [
      {
        name: 'ConnectionStrings__Redis'
        secretRef: 'redis'
      }
      {
        name: 'ConnectionStrings__EventBus'
        secretRef: 'eventbus'
      }
      {
        name: 'Identity__Url'
        value: identityUrl
      }
    ]
    secrets: [
      {
        name: 'redis'
        value: redisConnectionString
      }
      {
        name: 'eventbus'
        value: rabbitMqConnectionString
      }
    ]
    tags: tags
  }
}

module catalog './modules/container-app.bicep' = {
  name: 'catalog'
  params: {
    location: location
    name: catalogName
    managedEnvironmentId: containerAppsEnvironment.outputs.id
    containerRegistryName: containerRegistryName
    image: '${containerRegistryName}.azurecr.io/catalog-api:${imageTag}'
    environmentVariables: [
      {
        name: 'ConnectionStrings__catalogdb'
        secretRef: 'catalogdb'
      }
      {
        name: 'ConnectionStrings__EventBus'
        secretRef: 'eventbus'
      }
    ]
    secrets: [
      {
        name: 'catalogdb'
        value: catalogConnectionString
      }
      {
        name: 'eventbus'
        value: rabbitMqConnectionString
      }
    ]
    tags: tags
  }
}

module ordering './modules/container-app.bicep' = {
  name: 'ordering'
  params: {
    location: location
    name: orderingName
    managedEnvironmentId: containerAppsEnvironment.outputs.id
    containerRegistryName: containerRegistryName
    image: '${containerRegistryName}.azurecr.io/ordering-api:${imageTag}'
    environmentVariables: [
      {
        name: 'ConnectionStrings__orderingdb'
        secretRef: 'orderingdb'
      }
      {
        name: 'ConnectionStrings__EventBus'
        secretRef: 'eventbus'
      }
      {
        name: 'Identity__Url'
        value: identityUrl
      }
    ]
    secrets: [
      {
        name: 'orderingdb'
        value: orderingConnectionString
      }
      {
        name: 'eventbus'
        value: rabbitMqConnectionString
      }
    ]
    tags: tags
  }
}

module web './modules/container-app.bicep' = {
  name: 'web'
  params: {
    location: location
    name: webName
    managedEnvironmentId: containerAppsEnvironment.outputs.id
    containerRegistryName: containerRegistryName
    image: '${containerRegistryName}.azurecr.io/webapp:${imageTag}'
    externalIngress: true
    environmentVariables: [
      {
        name: 'ConnectionStrings__EventBus'
        secretRef: 'eventbus'
      }
      {
        name: 'IdentityUrl'
        value: identityUrl
      }
      {
        name: 'CallBackUrl'
        value: webAppUrl
      }
      {
        name: 'services__basket-api__http__0'
        value: 'http://${basketName}'
      }
      {
        name: 'services__catalog-api__http__0'
        value: 'http://${catalogName}'
      }
      {
        name: 'services__ordering-api__http__0'
        value: 'http://${orderingName}'
      }
    ]
    secrets: [
      {
        name: 'eventbus'
        value: rabbitMqConnectionString
      }
    ]
    tags: tags
  }
}

output containerAppsEnvironmentName string = environmentName
output containerRegistryName string = containerRegistryName
output identityUrl string = identityUrl
output webAppUrl string = webAppUrl
