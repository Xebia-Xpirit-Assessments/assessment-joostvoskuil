param location string
param name string
param administratorLogin string
@secure()
param administratorPassword string
param tags object = {}

module server 'br/public:avm/res/db-for-postgre-sql/flexible-server:0.10.0' = {
  params: {
    name: name
    location: location
    tags: tags
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    autoGrow: 'Disabled'
    backupRetentionDays: 7
    databases: [
      {
        name: 'catalogdb'
        charset: 'UTF8'
        collation: 'en_US.utf8'
      }
      {
        name: 'identitydb'
        charset: 'UTF8'
        collation: 'en_US.utf8'
      }
      {
        name: 'orderingdb'
        charset: 'UTF8'
        collation: 'en_US.utf8'
      }
    ]
    enableTelemetry: false
    firewallRules: [
      {
        name: 'AllowAzureServices'
        startIpAddress: '0.0.0.0'
        endIpAddress: '0.0.0.0'
      }
    ]
    geoRedundantBackup: 'Disabled'
    highAvailability: 'Disabled'
    publicNetworkAccess: 'Enabled'
    skuName: 'Standard_B1ms'
    storageSizeGB: 32
    tier: 'Burstable'
    version: '16'
  }
}

output fullyQualifiedDomainName string = server.outputs.fqdn
