param location string
param name string
param tagValues object
param hostingPlanName string
param appInnsightInstrKey string

param functionWorkerRuntime string
@secure()
param connectionString string
@secure()
param appInsightConnString string

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  kind: 'functionapp,linux'
  tags: tagValues
  properties: {
    reserved: true
    serverFarmId: resourceId('Microsoft.Web/serverfarms', hostingPlanName)
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(resourceId('Microsoft.Insights/components', name), '2020-02-02').InstrumentationKey
        }
        {
          name: 'APPINSIGHTS_CONNECTION_STRING'
          value: appInsightConnString
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
          value: name
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

output name string = functionApp.name
output functionAppUrl string = functionApp.properties.defaultHostName
output functionAppId string = functionApp.id
