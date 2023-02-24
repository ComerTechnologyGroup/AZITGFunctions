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

module resourceGroupModule './modules/resourceGroup.module.bicep' = {
  name: 'resourceGroup'
  params: {
    location: location
    functionAppName: functionAppName
    tagValues: tagValues
  }
}

module storageModule './modules/storage.module.bicep' = {
  scope: az.resourceGroup(resourceGroupModule.name)
  name: 'storageName'
  params: {
    location: location
    functionAppName: functionAppName
    tagValues: union(tagValues, {
        resourceGroup: az.resourceGroup(resourceGroupModule.name)
      })
  }
}

module appInsightModule './modules/appInsight.module.bicep' = {
  scope: az.resourceGroup(resourceGroupModule.name)
  name: 'appInsightName'
  params: {
    location: location
    functionAppName: 'func-itglue-${uniqueString(resourceGroupModule.outputs.resourceGroupId)}'
    tagValues: union(tagValues, {
        resourceGroup: az.resourceGroup(resourceGroupModule.name)
      })
  }
}

module hostingPlanModule './modules/hostingPlan.module.bicep' = {
  scope: az.resourceGroup(resourceGroupModule.name)
  name: 'hostingPlanName'
  params: {
    location: location
    functionAppName: 'func-itglue-${uniqueString(resourceGroupModule.outputs.resourceGroupId)}'
    tagValues: union(tagValues, {
        resourceGroup: az.resourceGroup(resourceGroupModule.name)
      })
  }
}

module functionAppModule './modules/functionApp.module.bicep' = {
  scope: az.resourceGroup(resourceGroupModule.name)
  name: 'functionAppName'
  params: {
    location: location
    functionAppName: 'func-itglue-${uniqueString(resourceGroupModule.outputs.resourceGroupId)}'
    functionWorkerRuntime: 'powershell'
    hostingPlanName: hostingPlanModule.outputs.hostingPlanName
    connectionString: storageModule.outputs.connectionString
    tagValues: union(tagValues, {
        resourceGroup: az.resourceGroup(resourceGroupModule.name)
      })
  }
}

@description('The name of the resource group')
output rgName string = resourceGroupModule.outputs.resourceGroupName

@description('The resource ID of the resource group.')
output resourceId string = resourceGroupModule.outputs.resourceGroupId

@description('The location the resource was deployed into.')
output location string = location
