@description('The location you want to deploy the app to')
param azureLocation string = resourceGroup().location

@description('The desired Azure function name')
param azureFunctionName string

@description('Azure Storage Account Name')
param azureStorageAccount string

@description('Azure Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param azureStorageAccountType string = 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: azureStorageAccount
  location: azureLocation
  sku: {
    name: azureStorageAccountType
  }
  kind: 'Storage'
}

resource AZITGFunctions 'Microsoft.Web/sites@2022-03-01' = {
  name: azureFunctionName
  kind: 'functionapp'
  location: azureLocation
  tags: {
    DateCreated: '02/21/2023'
  }
  properties: {
    name: 'AZITGFunctions'
    webSpace: 'MSPResources-WestUSwebspace'
    selfLink: 'https://waws-prod-bay-179.api.azurewebsites.windows.net:454/subscriptions/4b6cdc2b-b1a5-441d-bf0b-dccc2afa034a/webspaces/MSPResources-WestUSwebspace/sites/AZITGFunctions'
    enabled: true
    adminEnabled: true
    siteProperties: {
      metadata: null
      properties: [
        {
          name: 'LinuxFxVersion'
          value: ''
        }
        {
          name: 'WindowsFxVersion'
          value: null
        }
      ]
      appSettings: null
    }
    csrs: []
    hostNameSslStates: [
      {
        name: 'azitgfunctions.azurewebsites.net'
        sslState: 'Disabled'
        ipBasedSslState: 'NotConfigured'
        hostType: 'Standard'
      }
      {
        name: 'azitgfunctions.scm.azurewebsites.net'
        sslState: 'Disabled'
        ipBasedSslState: 'NotConfigured'
        hostType: 'Repository'
      }
    ]
    serverFarmId: '/subscriptions/4b6cdc2b-b1a5-441d-bf0b-dccc2afa034a/resourceGroups/MSPResources/providers/Microsoft.Web/serverfarms/ASP-AZITGFunctions-b1a6'
    reserved: false
    isXenon: false
    hyperV: false
    storageRecoveryDefaultState: 'Running'
    contentAvailabilityState: 'Normal'
    runtimeAvailabilityState: 'Normal'
    dnsConfiguration: {
    }
    vnetRouteAllEnabled: false
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: ''
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 200
      minimumElasticInstanceCount: 0
    }
    deploymentId: 'AZITGFunctions'
    sku: 'Dynamic'
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    customDomainVerificationId: 'C13938C8C529DDBE6666A733411A08509538DD3B65F145B4A101F5A29CE8AEE6'
    kind: 'functionapp'
    inboundIpAddress: '40.112.243.57'
    possibleInboundIpAddresses: '40.112.243.57'
    ftpUsername: 'AZITGFunctions\\$AZITGFunctions'
    ftpsHostName: 'ftps://waws-prod-bay-179.ftp.azurewebsites.windows.net/site/wwwroot'
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    siteDisabledReason: 0
    homeStamp: 'waws-prod-bay-179'
    tags: {
      DateCreated: '02/21/2023'
    }
    httpsOnly: false
    redundancyMode: 'None'
    privateEndpointConnections: []
    eligibleLogCategories: 'FunctionAppLogs'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
    defaultHostNameScope: 'Global'
  }
}
