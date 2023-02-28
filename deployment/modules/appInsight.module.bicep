param location string
param name string
param tagValues object
targetScope = 'resourceGroup'

resource applicationInsight 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tagValues
  properties: {
    Application_Type: 'web'
  }
  kind: 'web'
}

var appInsightConnString = applicationInsight.properties.ConnectionString

output appInsightName string = applicationInsight.properties.Name
output appInsightConnStringOutput string = appInsightConnString
output appInsightInstrKey string = applicationInsight.properties.InstrumentationKey
