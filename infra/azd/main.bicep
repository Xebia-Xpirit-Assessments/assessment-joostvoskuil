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

@allowed([
  'all'
  'webapp'
  'identity-api'
  'basket-api'
  'catalog-api'
  'ordering-api'
])
@description('The application service to provision. Use all for a full reconciliation.')
param serviceName string = 'all'

@description('CAF instance number.')
param instance string = '001'

@description('The shared ACR name created by shared-registry.bicep.')
param containerRegistryName string

@description('The resource group that owns the shared ACR.')
param containerRegistryResourceGroupName string

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

module identityImage './fetch-container-image.bicep' = if (serviceName == 'all' || serviceName == 'identity-api') {
  name: 'identity-image'
  params: {
    exists: identityApiExists
    name: identityName
  }
}

module identity '../modules/container-app.bicep' = if (serviceName == 'all' || serviceName == 'identity-api') {
  name: 'identity'
  params: {
    location: location
    name: identityName
    managedEnvironmentId: containerAppsEnvironment.id
    containerRegistryName: containerRegistryName
    image: identityImage.?outputs.containers[?0].?image ?? placeholderImage
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

module identityAcrPull '../modules/acr-pull-assignment.bicep' = if (serviceName == 'all' || serviceName == 'identity-api') {
  name: 'identity-acr-pull'
  scope: resourceGroup(containerRegistryResourceGroupName)
  params: {
    containerRegistryName: containerRegistryName
    principalId: identity!.outputs.identityPrincipalId
  }
}

module basketImage './fetch-container-image.bicep' = if (serviceName == 'all' || serviceName == 'basket-api') {
  name: 'basket-image'
  params: {
    exists: basketApiExists
    name: basketName
  }
}

module basket '../modules/container-app.bicep' = if (serviceName == 'all' || serviceName == 'basket-api') {
  name: 'basket'
  params: {
    location: location
    name: basketName
    managedEnvironmentId: containerAppsEnvironment.id
    containerRegistryName: containerRegistryName
    image: basketImage.?outputs.containers[?0].?image ?? placeholderImage
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

module basketAcrPull '../modules/acr-pull-assignment.bicep' = if (serviceName == 'all' || serviceName == 'basket-api') {
  name: 'basket-acr-pull'
  scope: resourceGroup(containerRegistryResourceGroupName)
  params: {
    containerRegistryName: containerRegistryName
    principalId: basket!.outputs.identityPrincipalId
  }
}

module catalogImage './fetch-container-image.bicep' = if (serviceName == 'all' || serviceName == 'catalog-api') {
  name: 'catalog-image'
  params: {
    exists: catalogApiExists
    name: catalogName
  }
}

module catalog '../modules/container-app.bicep' = if (serviceName == 'all' || serviceName == 'catalog-api') {
  name: 'catalog'
  params: {
    location: location
    name: catalogName
    managedEnvironmentId: containerAppsEnvironment.id
    containerRegistryName: containerRegistryName
    image: catalogImage.?outputs.containers[?0].?image ?? placeholderImage
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

module catalogAcrPull '../modules/acr-pull-assignment.bicep' = if (serviceName == 'all' || serviceName == 'catalog-api') {
  name: 'catalog-acr-pull'
  scope: resourceGroup(containerRegistryResourceGroupName)
  params: {
    containerRegistryName: containerRegistryName
    principalId: catalog!.outputs.identityPrincipalId
  }
}

module orderingImage './fetch-container-image.bicep' = if (serviceName == 'all' || serviceName == 'ordering-api') {
  name: 'ordering-image'
  params: {
    exists: orderingApiExists
    name: orderingName
  }
}

module ordering '../modules/container-app.bicep' = if (serviceName == 'all' || serviceName == 'ordering-api') {
  name: 'ordering'
  params: {
    location: location
    name: orderingName
    managedEnvironmentId: containerAppsEnvironment.id
    containerRegistryName: containerRegistryName
    image: orderingImage.?outputs.containers[?0].?image ?? placeholderImage
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

module orderingAcrPull '../modules/acr-pull-assignment.bicep' = if (serviceName == 'all' || serviceName == 'ordering-api') {
  name: 'ordering-acr-pull'
  scope: resourceGroup(containerRegistryResourceGroupName)
  params: {
    containerRegistryName: containerRegistryName
    principalId: ordering!.outputs.identityPrincipalId
  }
}

module webImage './fetch-container-image.bicep' = if (serviceName == 'all' || serviceName == 'webapp') {
  name: 'web-image'
  params: {
    exists: webappExists
    name: webName
  }
}

module web '../modules/container-app.bicep' = if (serviceName == 'all' || serviceName == 'webapp') {
  name: 'web'
  params: {
    location: location
    name: webName
    managedEnvironmentId: containerAppsEnvironment.id
    containerRegistryName: containerRegistryName
    image: webImage.?outputs.containers[?0].?image ?? placeholderImage
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

module webAcrPull '../modules/acr-pull-assignment.bicep' = if (serviceName == 'all' || serviceName == 'webapp') {
  name: 'web-acr-pull'
  scope: resourceGroup(containerRegistryResourceGroupName)
  params: {
    containerRegistryName: containerRegistryName
    principalId: web!.outputs.identityPrincipalId
  }
}

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = '${containerRegistryName}.azurecr.io'
