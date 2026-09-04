targetScope = 'resourceGroup'

@description('Azure region, for example swedencentral.')
param location string

@allowed([
  'stg'
  'prd'
])
param environment string

@description('CAF workload name.')
param workloadName string = 'eshop'

@description('CAF region abbreviation.')
param regionCode string = 'swe'

@description('CAF instance number.')
param instance string = '001'

@description('Environment-specific ACR name created by bootstrap.bicep.')
param containerRegistryName string

@allowed([
  'webapp'
  'identity-api'
  'basket-api'
  'catalog-api'
  'ordering-api'
])
@description('The one application service owned by this deployment.')
param service string

@description('Immutable image tag, normally the Git commit SHA.')
param imageTag string

param postgresAdministratorLogin string = 'eshopadmin'

@secure()
param postgresAdministratorPassword string

@secure()
param rabbitMqPassword string

var nameSuffix = '${workloadName}-${environment}-${regionCode}-${instance}'
var environmentName = 'cae-${nameSuffix}'
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

resource redis 'Microsoft.Cache/redisEnterprise@2024-03-01' existing = {
  name: redisName
}

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: environmentName
}

resource postgres 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' existing = {
  name: postgresName
}

resource redisDatabase 'Microsoft.Cache/redisEnterprise/databases@2024-03-01' existing = {
  parent: redis
  name: 'default'
}

var rabbitMqConnectionString = 'amqp://eshop:${uriComponent(rabbitMqPassword)}@${rabbitMqName}.internal.${containerAppsEnvironment.properties.defaultDomain}:5672'
var redisConnectionString = redisDatabase.listKeys().primaryKey
var identityUrl = 'https://${identityName}.${containerAppsEnvironment.properties.defaultDomain}'
var webAppUrl = 'https://${webName}.${containerAppsEnvironment.properties.defaultDomain}'
var catalogConnectionString = 'Host=${postgres.properties.fullyQualifiedDomainName};Port=5432;Database=catalogdb;Username=${postgresAdministratorLogin};Password=${postgresAdministratorPassword};Ssl Mode=Require;Trust Server Certificate=true'
var identityConnectionString = 'Host=${postgres.properties.fullyQualifiedDomainName};Port=5432;Database=identitydb;Username=${postgresAdministratorLogin};Password=${postgresAdministratorPassword};Ssl Mode=Require;Trust Server Certificate=true'
var orderingConnectionString = 'Host=${postgres.properties.fullyQualifiedDomainName};Port=5432;Database=orderingdb;Username=${postgresAdministratorLogin};Password=${postgresAdministratorPassword};Ssl Mode=Require;Trust Server Certificate=true'

module identity './modules/container-app.bicep' = if (service == 'identity-api') {
  name: 'identity'
  params: {
    location: location
    name: identityName
    managedEnvironmentId: containerAppsEnvironment.id
    containerRegistryName: containerRegistryName
    image: '${registry.properties.loginServer}/identity-api:${imageTag}'
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

module basket './modules/container-app.bicep' = if (service == 'basket-api') {
  name: 'basket'
  params: {
    location: location
    name: basketName
    managedEnvironmentId: containerAppsEnvironment.id
    containerRegistryName: containerRegistryName
    image: '${registry.properties.loginServer}/basket-api:${imageTag}'
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

module catalog './modules/container-app.bicep' = if (service == 'catalog-api') {
  name: 'catalog'
  params: {
    location: location
    name: catalogName
    managedEnvironmentId: containerAppsEnvironment.id
    containerRegistryName: containerRegistryName
    image: '${registry.properties.loginServer}/catalog-api:${imageTag}'
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

module ordering './modules/container-app.bicep' = if (service == 'ordering-api') {
  name: 'ordering'
  params: {
    location: location
    name: orderingName
    managedEnvironmentId: containerAppsEnvironment.id
    containerRegistryName: containerRegistryName
    image: '${registry.properties.loginServer}/ordering-api:${imageTag}'
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

module web './modules/container-app.bicep' = if (service == 'webapp') {
  name: 'web'
  params: {
    location: location
    name: webName
    managedEnvironmentId: containerAppsEnvironment.id
    containerRegistryName: containerRegistryName
    image: '${registry.properties.loginServer}/webapp:${imageTag}'
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

output serviceName string = service
output containerAppName string = service == 'webapp' ? webName : service == 'identity-api' ? identityName : service == 'basket-api' ? basketName : service == 'catalog-api' ? catalogName : orderingName
