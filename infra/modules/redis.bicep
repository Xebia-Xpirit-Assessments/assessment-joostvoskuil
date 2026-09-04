param location string
param name string
param tags object = {}

module cache 'br/public:avm/res/cache/redis-enterprise:0.5.1' = {
  params: {
    name: name
    location: location
    tags: tags
    database: {
      accessKeysAuthentication: 'Enabled'
      clientProtocol: 'Encrypted'
      clusteringPolicy: 'NoCluster'
    }
    enableTelemetry: false
    highAvailability: 'Disabled'
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    skuName: 'Balanced_B0'
  }
}

output hostName string = cache.outputs.hostName

@secure()
output primaryStackExchangeRedisConnectionString string = cache.outputs.primaryStackExchangeRedisConnectionString!
