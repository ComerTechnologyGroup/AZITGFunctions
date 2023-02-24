param location string
param functionAppName string
param tagValues object = {}

resource applicationInsight 'Microsoft.Insights/components@2020-02-02' = {
  name: functionAppName
  location: location
  tags: tagValues
  properties: {
    Application_Type: 'web'
  }
  kind: 'web'
}

output appInsightName string = applicationInsight.name
output appInsightId string = applicationInsight.id
