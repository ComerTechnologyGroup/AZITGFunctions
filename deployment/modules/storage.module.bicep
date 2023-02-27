targetScope = 'resourceGroup'
param name string
param tagValues object
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Standard_RAGRS'
  'Premium_LRS'
  'Premium_ZRS'
])
@description('Storage account SKU name')
param storageSkuName string = 'Standard_LRS'
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: name
  location: location
  sku: {
    name: storageSkuName
  }
  kind: 'Storagev2'
  tags: tagValues
}

var connectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'

output storageId string = storageAccount.id
output storageName string = storageAccount.name
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
output connectionString string = connectionString
