/*
 ** Bicep Template for Azure Powershell function App for IT Glue Function
 ** Provided by: Comer Technology Group (CTG)
 ** Website: htts://comertechnology.com
*/
targetScope = 'subscription'
/*
* Parameters
*/
param resourceGroupName string = 'rg-${appName}-${suffix}'
@description('Optional. Location of the Resource Group. It uses the deployment\'s location when not provided.')
param location string = deployment().location
@description('Optional. Suffix for the resource names. It uses a unique string when not provided.')
param suffix string = toLower('${substring(uniqueString(subscription().id), 5)}')
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

/* Building the Resource Group to be used for the remaining modules*/

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tagValues
}
output resourceGroupId string = resourceGroup.id

/*
* Variables
*/
var functionName = toLower('fnc-${appName}-${suffix}')
var storageName = toLower('st${appName}${suffix}')
var appInsighName = toLower('ai-${appName}-${suffix}')
var hostingPlanName = toLower('hp-${appName}-${suffix}')

/* Building the Storage */
module storageModule './modules/storage.module.bicep' = {
  name: 'storageDeployment-${currentDate}'
  scope: resourceGroup
  params: {
    location: resourceGroup.location
    name: storageName
    tagValues: tagValues
  }
}

/* Building the App Insights for the Function App */
module appInsightModule './modules/appInsight.module.bicep' = {
  name: 'appInsightDeployment-${currentDate}'
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
  name: 'hostingPlanDeployment-${currentDate}'
  scope: resourceGroup
  params: {
    location: resourceGroup.location
    name: hostingPlanName
    tagValues: tagValues
  }
  dependsOn: [
    storageModule
    appInsightModule
  ]
}

/* Building the Function App */
module functionAppModule './modules/functionApp.module.bicep' = {
  name: 'functionAppDeployment-${currentDate}'
  scope: resourceGroup
  params: {
    location: resourceGroup.location
    appInnsightInstrKey: appInsightModule.outputs.appInsightInstrKey
    appInsightConnString: appInsightModule.outputs.appInsightConnStringOutput
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
