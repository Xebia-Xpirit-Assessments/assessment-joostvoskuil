param location string
param name string
param tags object = {}

module cache 'br/public:avm/res/cache/redis:0.18.0' = {
  params: {
    name: name
    location: location
    tags: tags
    capacity: 0
    enableNonSslPort: false
    enableTelemetry: false
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    skuName: 'Basic'
  }
}

output hostName string = cache.outputs.hostName
