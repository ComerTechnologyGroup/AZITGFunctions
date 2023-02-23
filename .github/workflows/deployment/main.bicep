/*
 * Azure IT Glue Functions - Starter Pack
 * This Bicep module helps to automate resource name generations
 * and creation following best practicing conventions.
 *
 * Authors: Quinntin Comer (qcomer@comertechnology.com)
 * Company: Comer Technology Group (CTG)
 * Website: https://www.comertechnologygroup.com
 * Github: https://github.com/francesco-sodano/AZNames-bicep
 * 
 */
/*
 ** Parameters
 */

@description('The name of the Azure Function app.')
param functionAppName string = 'func-itglue-${uniqueString(resourceGroup().id)}'

@description('The name of the Azure Function app.')
param resourceGroupName string = functionAppName

@description('Location for all resources.')
param location string = resourceGroup().location

param currentDate string = utcNow('yyyy-MM-dd')

@description('Location for Application Insights')
param appInsightsLocation string = resourceGroup().location

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

/*
 ** Variables
 */
var hostingPlanName = functionAppName
var applicationInsightName = functionAppName
var storageAccountName = functionAppName
var tagValues = {
  createdBy: 'Github Action'
  deploymentDate: currentDate
  product: 'function'
  relatedResource: functionAppName
}
var functionWorkerRuntime = 'powershell'

/*
 ** Resources
 */

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageSkuName
  }
  kind: 'Storage'
  tags: tagValues
}

resource applicationInsight 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightName
  location: location
  tags: tagValues
  properties: {
    Application_Type: 'web'
  }
  kind: 'web'
}

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

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  properties: {
    reserved: true
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(resourceId('Microsoft.Insights/components', functionAppName), '2020-02-02').InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
      ]
    }
  }
  dependsOn: [
    applicationInsight
  ]
}
