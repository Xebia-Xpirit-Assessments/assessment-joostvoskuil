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

@description('The environment-specific ACR name created by main.bicep.')
param containerRegistryName string

@description('PostgreSQL administrator login.')
param postgresAdministratorLogin string = 'eshopadmin'

@secure()
@description('PostgreSQL administrator password. Supply through the azd environment.')
param postgresAdministratorPassword string

@secure()
@description('RabbitMQ application password. Supply through the azd environment.')
param rabbitMqPassword string

@description('Whether the WebApp container app already exists. False only for first-time provisioning.')
param webappExists bool = true

@description('Whether the Identity API container app already exists. False only for first-time provisioning.')
param identityApiExists bool = true

@description('Whether the Basket API container app already exists. False only for first-time provisioning.')
param basketApiExists bool = true

@description('Whether the Catalog API container app already exists. False only for first-time provisioning.')
param catalogApiExists bool = true

@description('Whether the Ordering API container app already exists. False only for first-time provisioning.')
param orderingApiExists bool = true

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
// azd's placeholder image for a container app that has never received a real 'azd deploy' yet.
var placeholderImage = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
var tags = {
  application: workloadName
  environment: environment
  managedBy: 'azd'
  workload: workloadName
  'azd-env-name': environment
}

resource redis 'Microsoft.Cache/redisEnterprise@2025-04-01' existing = {
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

resource redisDatabase 'Microsoft.Cache/redisEnterprise/databases@2025-04-01' existing = {
  parent: redis
  name: 'default'
}

var rabbitMqConnectionString = 'amqp://eshop:${uriComponent(rabbitMqPassword)}@${rabbitMqName}.internal.${containerAppsEnvironment.properties.defaultDomain}:5672'
// StackExchange.Redis requires host:port plus a password= keyword, not the bare access key.
var redisConnectionString = '${redis.properties.hostName}:${redisDatabase.properties.port},password=${redisDatabase.listKeys().primaryKey},ssl=True,abortConnect=False'
var identityUrl = 'https://${identityName}.${containerAppsEnvironment.properties.defaultDomain}'
var webAppUrl = 'https://${webName}.${containerAppsEnvironment.properties.defaultDomain}'
var catalogConnectionString = 'Host=${postgres.properties.fullyQualifiedDomainName};Port=5432;Database=catalogdb;Username=${postgresAdministratorLogin};Password=${postgresAdministratorPassword};Ssl Mode=Require;Trust Server Certificate=true'
var identityConnectionString = 'Host=${postgres.properties.fullyQualifiedDomainName};Port=5432;Database=identitydb;Username=${postgresAdministratorLogin};Password=${postgresAdministratorPassword};Ssl Mode=Require;Trust Server Certificate=true'
var orderingConnectionString = 'Host=${postgres.properties.fullyQualifiedDomainName};Port=5432;Database=orderingdb;Username=${postgresAdministratorLogin};Password=${postgresAdministratorPassword};Ssl Mode=Require;Trust Server Certificate=true'

module identityImage './fetch-container-image.bicep' = {
  name: 'identity-image'
  params: {
    exists: identityApiExists
    name: identityName
  }
}

module identity '../modules/container-app.bicep' = {
  name: 'identity'
  params: {
    location: location
    name: identityName
    managedEnvironmentId: containerAppsEnvironment.id
    containerRegistryName: containerRegistryName
    image: length(identityImage.outputs.containers) > 0 ? identityImage.outputs.containers[0].image : placeholderImage
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
    tags: union(tags, { 'azd-service-name': 'identity-api' })
  }
}

module basketImage './fetch-container-image.bicep' = {
  name: 'basket-image'
  params: {
    exists: basketApiExists
    name: basketName
  }
}

module basket '../modules/container-app.bicep' = {
  name: 'basket'
  params: {
    location: location
    name: basketName
    managedEnvironmentId: containerAppsEnvironment.id
    containerRegistryName: containerRegistryName
    image: length(basketImage.outputs.containers) > 0 ? basketImage.outputs.containers[0].image : placeholderImage
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
    tags: union(tags, { 'azd-service-name': 'basket-api' })
  }
}

module catalogImage './fetch-container-image.bicep' = {
  name: 'catalog-image'
  params: {
    exists: catalogApiExists
    name: catalogName
  }
}

module catalog '../modules/container-app.bicep' = {
  name: 'catalog'
  params: {
    location: location
    name: catalogName
    managedEnvironmentId: containerAppsEnvironment.id
    containerRegistryName: containerRegistryName
    image: length(catalogImage.outputs.containers) > 0 ? catalogImage.outputs.containers[0].image : placeholderImage
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
    tags: union(tags, { 'azd-service-name': 'catalog-api' })
  }
}

module orderingImage './fetch-container-image.bicep' = {
  name: 'ordering-image'
  params: {
    exists: orderingApiExists
    name: orderingName
  }
}

module ordering '../modules/container-app.bicep' = {
  name: 'ordering'
  params: {
    location: location
    name: orderingName
    managedEnvironmentId: containerAppsEnvironment.id
    containerRegistryName: containerRegistryName
    image: length(orderingImage.outputs.containers) > 0 ? orderingImage.outputs.containers[0].image : placeholderImage
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
    tags: union(tags, { 'azd-service-name': 'ordering-api' })
  }
}

module webImage './fetch-container-image.bicep' = {
  name: 'web-image'
  params: {
    exists: webappExists
    name: webName
  }
}

module web '../modules/container-app.bicep' = {
  name: 'web'
  params: {
    location: location
    name: webName
    managedEnvironmentId: containerAppsEnvironment.id
    containerRegistryName: containerRegistryName
    image: length(webImage.outputs.containers) > 0 ? webImage.outputs.containers[0].image : placeholderImage
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
    tags: union(tags, { 'azd-service-name': 'webapp' })
  }
}

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = registry.properties.loginServer
