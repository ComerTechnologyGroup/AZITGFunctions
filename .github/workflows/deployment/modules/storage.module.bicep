param location string
param functionAppName string
param tagValues object = {}

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

var storageAccountName = functionAppName

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: toLower(storageAccountName)
  location: location
  sku: {
    name: storageSkuName
  }a
  kind: 'Storage'
  tags: tagValues
}

output storageId string = storageAccount.id
output storageName string = storageAccount.name
output primaryKey string = listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
output connectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
