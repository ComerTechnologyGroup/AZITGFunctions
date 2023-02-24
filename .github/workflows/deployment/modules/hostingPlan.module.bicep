param location string
param functionAppName string
param tagValues object = {}

var hostingPlanName = functionAppName
targetScope = 'resourceGroup'

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
  }
  properties: {
    reserved: false
  }
  tags: tagValues
}

output hostingPlanName string = hostingPlan.name
output hostingPlanId string = hostingPlan.id
