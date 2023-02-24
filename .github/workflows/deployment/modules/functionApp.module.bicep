param location string
param functionAppName string
param tagValues object
param hostingPlanName string
param storageAccountName string
param storageAccount object
param appInsightName string
param functionWorkerRuntime string
@secure()
param primaryKey string
@secure()
param connectionString string

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  properties: {
    reserved: true
    serverFarmId: resourceId('Microsoft.Web/serverfarms', hostingPlanName)
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(resourceId('Microsoft.Insights/components', functionAppName), '2020-02-02').InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: connectionString
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: connectionString
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
      ]
    }
  }
}

output functionAppName string = functionApp.name
output functionAppUrl string = functionApp.properties.defaultHostName
output functionAppId string = functionApp.id
