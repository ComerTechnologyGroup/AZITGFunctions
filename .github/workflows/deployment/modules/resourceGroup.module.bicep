param location string
param functionAppName string
param tagValues object
targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: functionAppName
  location: location
  tags: tagValues
}

output resourceGroupId string = resourceGroup.id
output resourceGroupName string = resourceGroup.name
