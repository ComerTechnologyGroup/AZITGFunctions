/*
 ** Bicep Template for Azure Powershell function App for IT Glue Function
 ** Provided by: Comer Technology Group (CTG)
 ** Website: htts://comertechnology.com
*/
targetScope = 'subscription'
/*
* Parameters
*/
@description('Optional. Subscription ID. It uses the current subscription when not provided.')
param subscriptionId string
@description('Optional. Location of the Resource Group. It uses the deployment\'s location when not provided.')
param location string = deployment().location
@description('Optional. Suffix for the resource names. It uses a unique string when not provided.')
param suffix string = substring(uniqueString(subscription().id), 5)
@description('Optional. Name of the application. It uses azureitglue when not provided.')
param appName string = 'azureitglue'
@description('Gathers the current date to be used in the tag values.')
param currentDate string = utcNow('yyyy-MM-dd')
@description('Optional. Tags to be applied to the resources. It uses the default tags when not provided.')
param tagValues object = {
  createdBy: 'Github Action'
  deploymentDate: currentDate
  product: 'function'
  environment: 'prod'
  appName: '${appName}-${suffix}'
  source: 'Github'
}

/* Resource Group Name */
var resourceGroupName = 'rg-${appName}-${suffix}'

/* Building the Resource Group to be used fore the remaining modules*/
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tagValues
}

/*
* Variables
*/
var functionName = toLower('fnc-${appName}-${uniqueString(resourceGroup.id)}')
var storageName = toLower(substring('st${appName}${uniqueString(resourceGroup.id)}', 24))
var appInsighName = toLower('ai-${appName}-${uniqueString(resourceGroup.id)}')
var hostingPlanName = toLower('hp-${appName}-${uniqueString(resourceGroup.id)}')

output storageNameOutput string = storageName

/* Building the Storage */
module storageModule './modules/storage.module.bicep' = {
  name: 'storageDeployment'
  scope: resourceGroup
  params: {
    location: resourceGroup.location
    name: storageName
    tagValues: tagValues
  }
}

/* Building the App Insights for the Function App */
module appInsightModule './modules/appInsight.module.bicep' = {
  name: 'appInsightDeployment'
  scope: resourceGroup
  params: {
    location: location
    name: appInsighName
    tagValues: tagValues
  }
  dependsOn: [
    storageModule
  ]
}

/* Building the Hosting Plan */
module hostingPlanModule './modules/hostingPlan.module.bicep' = {
  name: 'hostingPlanDeployment'
  scope: resourceGroup
  params: {
    location: resourceGroup.location
    name: hostingPlanName
    tagValues: tagValues
  }
  dependsOn: [
    storageModule
  ]
}

/* Building the Function App */
module functionAppModule './modules/functionApp.module.bicep' = {
  name: 'functionAppDeployment'
  scope: resourceGroup
  params: {
    location: resourceGroup.location
    appInnsightInstrKey: appInsightModule.outputs.appInsightInstrKey
    appInsightConnString: appInsightModule.outputs.appInsightConnString
    name: functionName
    functionWorkerRuntime: 'powershell'
    hostingPlanName: hostingPlanModule.outputs.hostingPlanName
    connectionString: storageModule.outputs.connectionString
    tagValues: tagValues
  }
  dependsOn: [
    storageModule
    appInsightModule
    hostingPlanModule
  ]
}

/* Outputs */
@description('The name of the resource group')
output rgName string = resourceGroup.name
@description('The resource ID of the resource group.')
output resourceId string = resourceGroup.id
@description('The name of the storage account.')
output storageName string = storageModule.outputs.storageName
@description('The name of the app insights.')
output appInsightName string = appInsightModule.outputs.appInsightName
@description('The name of the hosting plan.')
output hostingPlanName string = hostingPlanModule.outputs.hostingPlanName
@description('The name of the function app.')
output functionAppName string = functionAppModule.outputs.name
@description('The location the resource was deployed into.')
output location string = location
@description('The URL of the function app')
output functionAppUrl string = functionAppModule.outputs.functionAppUrl
