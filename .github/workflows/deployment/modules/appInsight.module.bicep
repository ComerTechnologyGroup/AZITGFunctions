param location string
param functionAppName string
param tagValues object = {}
targetScope = 'resourceGroup'

resource applicationInsight 'Microsoft.Insights/components@2020-02-02' = {
  name: functionAppName
  location: location
  tags: tagValues
  properties: {
    Application_Type: 'web'
  }
  kind: 'web'
}

output appInsightName string = applicationInsight.properties.Name
output appInsightConnString string = applicationInsight.properties.ConnectionString
output appInsightInstrKey string = applicationInsight.properties.InstrumentationKey
