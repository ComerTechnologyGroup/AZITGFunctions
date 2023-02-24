targetScope = 'subscription'

@description('Optional. Location of the Resource Group. It uses the deployment\'s location when not provided.')
param location string = deployment().location
param functionAppName string = 'funcitglue${uniqueString(subscription().id)}'
param currentDate string = utcNow('yyyy-MM-dd')
param tagValues object = {
  createdBy: 'Github Action'
  deploymentDate: currentDate
  product: 'function'
  subscription: subscription().id
}
resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: functionAppName
  location: location
  tags: tagValues
}

module storageModule './modules/storage.module.bicep' = {
  scope: resourceGroup
  name: 'storageName'
  params: {
    location: location
    functionAppName: functionAppName
    tagValues: union(tagValues, {
        resourceGroup: resourceGroup
      })
  }
}

module appInsightModule './modules/appInsight.module.bicep' = {
  scope: resourceGroup
  name: 'appInsightName'
  params: {
    location: location
    functionAppName: 'func-itglue-${uniqueString(resourceGroup.id)}'
    tagValues: union(tagValues, {
        resourceGroup: resourceGroup
      })
  }
}

module hostingPlanModule './modules/hostingPlan.module.bicep' = {
  scope: resourceGroup
  name: 'hostingPlanName'
  params: {
    location: location
    functionAppName: 'func-itglue-${uniqueString(resourceGroup.id)}'
    tagValues: union(tagValues, {
        resourceGroup: resourceGroup
      })
  }
}

module functionAppModule './modules/functionApp.module.bicep' = {
  scope: resourceGroup
  name: 'functionAppName'
  params: {
    location: location
    functionAppName: 'func-itglue-${uniqueString(resourceGroup.id)}'
    functionWorkerRuntime: 'powershell'
    hostingPlanName: hostingPlanModule.outputs.hostingPlanName
    connectionString: storageModule.outputs.connectionString
    tagValues: union(tagValues, {
        resourceGroup: resourceGroup
      })
  }
}

@description('The name of the resource group')
output rgName string = resourceGroup.name

@description('The resource ID of the resource group.')
output resourceId string = resourceGroup.id

@description('The location the resource was deployed into.')
output location string = location
