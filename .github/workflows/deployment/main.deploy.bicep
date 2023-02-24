targetScope = 'subscription'

@description('Optional. Location of the Resource Group. It uses the deployment\'s location when not provided.')
param location string = deployment().location
param functionAppName string = 'func-itglue-${uniqueString(subscription().id)}'
param currentDate string = utcNow('yyyy-MM-dd')
param tagValues object = {
  createdBy: 'Github Action'
  deploymentDate: currentDate
  product: 'function'
  subscription: subscription().id
}
@allowed([ 'powershell' ])
param functionWorkerRuntime string = 'powershell'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: functionAppName
  location: location
  tags: tagValues
  properties: {}
}

module storageModule './modules/storage.module.bicep' = {
  scope: az.resourceGroup(resourceGroup.name)
  name: 'storageName'
  params: {
    location: resourceGroup.location
    functionAppName: 'func-itglue-${uniqueString(resourceGroup.id)}'
    tagValues: union(tagValues, {
        resourceGroup: resourceGroup.name
      })
  }
}

module appInsightModule './modules/appInsight.module.bicep' = {
  scope: az.resourceGroup(resourceGroup.name)
  name: 'appInsightName'
  params: {
    location: resourceGroup.location
    functionAppName: 'func-itglue-${uniqueString(resourceGroup.id)}'
    tagValues: union(tagValues, {
        resourceGroup: resourceGroup.name
      })
  }
}

module hostingPlanModule './modules/hostingPlan.module.bicep' = {
  scope: az.resourceGroup(resourceGroup.name)
  name: 'hostingPlanName'
  params: {
    location: resourceGroup.location
    functionAppName: 'func-itglue-${uniqueString(resourceGroup.id)}'
    tagValues: union(tagValues, {
        resourceGroup: resourceGroup.name
      })
  }
}

module functionAppModule './modules/functionApp.module.bicep' = {
  scope: az.resourceGroup(resourceGroup.name)
  name: 'functionAppName'
  params: {
    location: resourceGroup.location
    functionAppName: 'func-itglue-${uniqueString(resourceGroup.id)}'
    functionWorkerRuntime: functionWorkerRuntime
    storageAccountName: storageModule.outputs.storageName
    storageAccount: storageModule.outputs
    appInsightName: appInsightModule.outputs.appInsightName
    hostingPlanName: hostingPlanModule.outputs.hostingPlanName
    connectionString: storageModule.outputs.connectionString
    primaryKey: storageModule.outputs.primaryKey
    tagValues: union(tagValues, {
        resourceGroup: resourceGroup.name
      })
  }
}

@description('The name of the resource group')
output rgName string = resourceGroup.name

@description('The resource ID of the resource group.')
output resourceId string = resourceGroup.id

@description('The location the resource was deployed into.')
output location string = resourceGroup.location
