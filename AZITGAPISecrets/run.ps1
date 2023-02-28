# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

#region Azure AD Authentication
$ApplicationId = $env:ApplicationId
$ApplicationSecret = $env:ApplicationSecret
$SecureApplicationSecret = $ApplicationSecret | ConvertTo-SecureString -AsPlainText -Force
$TenantID = $env:TenantId
$RefreshToken = $env:RefreshToken
$ExchangeRefreshToken = $env:ExchangeRefreshToken
$UPN = $env:UPN
$credential = New-Object System.Management.Automation.PSCredential($ApplicationID, $SecureApplicationSecret)
#endregion

#region IT Glue API Information
$APIKEy = $env:ITGApiKey
$APIEndpoint = $env:APIEndpoint
$FlexAssetName = $env:FlexAssetName
$Description = $env:Description
#endregion

Import-LocalizedData -FileName requirements.psd1 -BindingVariable Modules
$modules.GetEnumerator() | ForEach-Object {
    if (-not(Get-Module -Name $_.name -ListAvailable)) {
        try {
            Install-Module -Name $_.name -Force -ErrorAction Stop | Out-Null
            Write-Output "Successfully installed module: $($_.name)"
        } catch {
            Write-Output "ERROR: Failed to install module: $($_.name). Result: $($_.exception.message)"
            exit 1
        }
    }
    try {
        if ($_.name -like '*Glue*') {
            Import-Module -Name $_.name -UseWindowsPowerShell -ErrorAction Stop | Out-Null
        } else {
            Import-Module -Name $_.name -ErrorAction Stop | Out-Null
        }
        Write-Output "Successfully imported Module: $($_.name)"
    } catch {
        Write-Output "ERROR: Failed to import Module: $($_.name). Result: $($_.exception.message)"
        exit 1
    }
}

$session = Get-PSSession -Name WinPSCompatSession

Invoke-Command -Session $session -Command {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}
#Settings IT-Glue logon information
Add-ITGlueBaseURI -base_uri $APIEndpoint
Add-ITGlueAPIKey $APIKEy

Write-Host 'Getting IT-Glue contact list' -ForegroundColor Green
$i = 0
$AllITGlueContacts = do {
    $Contacts = (Get-ITGlueContacts -page_size 1000 -page_number $i).data.attributes
    $i++
    $Contacts
    Write-Host "Retrieved $($Contacts.count) Contacts" -ForegroundColor Yellow
}while ($Contacts.count % 1000 -eq 0 -and $Contacts.count -ne 0)

Write-Host 'Generating unique ID List' -ForegroundColor Green

$DomainList = foreach ($Contact in $AllITGlueContacts) {
    $ITGDomain = ($contact.'contact-emails'.value -split '@')[1]
    [PSCustomObject]@{
        Domain   = $ITGDomain
        OrgID    = $Contact.'organization-id'
        Combined = "$($ITGDomain)$($Contact.'organization-id')"
    }
}


###Connect to your Own Partner Center to get a list of customers/tenantIDs #########
$aadGraphToken = New-PartnerAccessToken -ApplicationId $ApplicationId -Credential $credential -RefreshToken $refreshToken -Scopes 'https://graph.windows.net/.default' -ServicePrincipal -Tenant $tenantID
$graphToken = New-PartnerAccessToken -ApplicationId $ApplicationId -Credential $credential -RefreshToken $refreshToken -Scopes 'https://graph.microsoft.com/.default' -ServicePrincipal -Tenant $tenantID


Connect-MsolService -AdGraphAccessToken $aadGraphToken.AccessToken -MsGraphAccessToken $graphToken.AccessToken

$customers = Get-MsolPartnerContract -All
 
Write-Host "Found $($customers.Count) customers in Partner Center." -ForegroundColor DarkGreen

foreach ($customer in $customers) {
    Write-Host "Found $($customer.Name) in Partner Center" -ForegroundColor Green

    ###Get Access Token########
    $CustomerToken = New-PartnerAccessToken -ApplicationId $ApplicationId -Credential $credential -RefreshToken $refreshToken -Scopes 'https://graph.microsoft.com/.default' -Tenant $customer.TenantID
    $headers = @{ 'Authorization' = "Bearer $($CustomerToken.AccessToken)" }
    #region Get Tenant Applications
    try {
        $applications = (Invoke-RestMethod -Uri 'https://graph.microsoft.com/v1.0/applications' -Headers $headers -Method Get -ContentType 'application/json' -ErrorAction Stop)
        return $applications
    } catch {
        throw ''
    }
    if ($null -ne $applications) {
        foreach ($app in $applications) {

        }
    }
    #endregion
}
