@description('Optional. Location of the Resource Group. It uses the deployment\'s location when not provided.')
param location string = resourceGroup().location
param suffix string = uniqueString(subscription().id)
param prefix string = 'func-itglue'
param functionAppName string = '${prefix}-${suffix}'
param currentDate string = utcNow('yyyy-MM-dd')
param tagValues object = {
  createdBy: 'Github Action'
  deploymentDate: currentDate
  product: 'function'
  environment: 'prod'
  relatedFunction: functionAppName
}
var resourceGroupId = resourceGroup().id
var resourceGroupName = resourceGroup().name

module storageModule './modules/storage.module.bicep' = {
  name: 'storageName'
  params: {
    location: location
    functionAppName: functionAppName
    tagValues: tagValues
  }
}

module appInsightModule './modules/appInsight.module.bicep' = {
  name: 'appInsightName'
  params: {
    location: location
    functionAppName: 'func-itglue-${uniqueString(resourceGroupId)}'
    tagValues: tagValues
  }
}

module hostingPlanModule './modules/hostingPlan.module.bicep' = {
  name: 'hostingPlanName'
  params: {
    location: location
    functionAppName: 'func-itglue-${uniqueString(resourceGroupId)}'
    tagValues: tagValues
  }
}

module functionAppModule './modules/functionApp.module.bicep' = {
  name: 'functionAppName'
  params: {
    location: location
    appInnsightInstrKey: appInsightModule.outputs.appInsightInstrKey
    appInsightConnString: appInsightModule.outputs.appInsightConnString
    functionAppName: 'func-itglue-${uniqueString(resourceGroupId)}'
    functionWorkerRuntime: 'powershell'
    hostingPlanName: hostingPlanModule.outputs.hostingPlanName
    connectionString: storageModule.outputs.connectionString
    tagValues: tagValues
  }
}

@description('The name of the resource group')
output rgName string = resourceGroupName

@description('The resource ID of the resource group.')
output resourceId string = resourceGroupId

@description('The location the resource was deployed into.')
output location string = location

@description('The URL of the function app')
output functionAppUrl string = functionAppModule.outputs.functionAppUrl
