# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

######### Secrets #########
$ApplicationId = $env:ApplicationId
$ApplicationSecret = $env:ApplicationSecret
$TenantID = $env:TenantId
$RefreshToken = $env:RefreshToken
$ExchangeRefreshToken = $env:ExchangeRefreshToken
$UPN = $env:UPN
######### Secrets #########

########################## IT-Glue ############################
$APIKEy = $env:ITGApiKey
$APIEndpoint = $env:APIEndpoint
$FlexAssetName = $env:FlexAssetName
$Description = $env:Description
########################## IT-Glue ############################

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
        Import-Module -Name $_.name -UseWindowsPowerShell -ErrorAction Stop | Out-Null
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


write-host "Checking if Flexible Asset exists in IT-Glue." -foregroundColor green
$FilterID = (Get-ITGlueFlexibleAssetTypes -filter_name $FlexAssetName).data
if (!$FilterID) {
    write-host "Does not exist, creating new." -foregroundColor green
    $NewFlexAssetData =
    @{
        type          = 'flexible-asset-types'
        attributes    = @{
            name        = $FlexAssetName
            icon        = 'sitemap'
            description = $description
        }
        relationships = @{
            "flexible-asset-fields" = @{
                data = @(
                    @{
                        type       = "flexible_asset_fields"
                        attributes = @{
                            order           = 1
                            name            = "Default Domain Name"
                            kind            = "Text"
                            required        = $true
                            "show-in-list"  = $true
                            "use-for-title" = $true
                        }
                    },
                    @{
                        type       = "flexible_asset_fields"
                        attributes = @{
                            order          = 2
                            name           = "TenantID"
                            kind           = "Text"
                            required       = $false
                            "show-in-list" = $false
                        }
                    },
                    @{
                        type       = "flexible_asset_fields"
                        attributes = @{
                            order          = 3
                            name           = "Current Score"
                            kind           = "Text"
                            required       = $false
                            "show-in-list" = $false
                        }
                    },
                    @{
                        type       = "flexible_asset_fields"
                        attributes = @{
                            order          = 4
                            name           = "Secure Score Comparetives"
                            kind           = "Textbox"
                            required       = $false
                            "show-in-list" = $false
                        }
                    },
                    @{
                        type       = "flexible_asset_fields"
                        attributes = @{
                            order          = 5
                            name           = "Secure Score Settings"
                            kind           = "Textbox"
                            required       = $false
                            "show-in-list" = $false
                        }
                    }
                )
            }
        }
    }
    New-ITGlueFlexibleAssetTypes -Data $NewFlexAssetData
    $FilterID = (Get-ITGlueFlexibleAssetTypes -filter_name $FlexAssetName).data
}

write-host "Getting IT-Glue contact list" -ForegroundColor Green
$i = 0
$AllITGlueContacts = do {
    $Contacts = (Get-ITGlueContacts -page_size 1000 -page_number $i).data.attributes
    $i++
    $Contacts
    Write-Host "Retrieved $($Contacts.count) Contacts" -ForegroundColor Yellow
}while ($Contacts.count % 1000 -eq 0 -and $Contacts.count -ne 0)

write-host "Generating unique ID List" -ForegroundColor Green

$DomainList = foreach ($Contact in $AllITGlueContacts) {
    $ITGDomain = ($contact.'contact-emails'.value -split "@")[1]
    [PSCustomObject]@{
        Domain   = $ITGDomain
        OrgID    = $Contact.'organization-id'
        Combined = "$($ITGDomain)$($Contact.'organization-id')"
    }
}

$Scores = get-securescore -AllTenants -upn $upn -ApplicationSecret $ApplicationSecret -ApplicationId $ApplicationId -RefreshToken $RefreshToken

foreach ($Score in $scores) {
    $FlexAssetBody =
    @{
        type       = "flexible-assets"
        attributes = @{
            traits = @{
                "default-domain-name"       = $score.TenantName
                "tenantid"                  = $score.TenantID
                "current-score"             = "$($score.Scores.currentScore) of $($score.Scores.maxScore)"
                "secure-score-comparetives" = ($score.Scores.averageComparativeScores | convertto-html -Fragment | out-string) -replace "<th>", "<th style=`"background-color:#4CAF50`">"
                "secure-score-settings"     = ($score.Scores.controlScores | convertto-html -Fragment | out-string) -replace "<th>", "<th style=`"background-color:#4CAF50`">"
            }
        }
    }

    write-output "             Finding $($score.TenantName) in IT-Glue"

    $Domains = (Get-MsolDomain -TenantId $Score.TenantID).name
    $ORGId = foreach ($Domain in $Domains) {
        ($domainList | Where-Object { $_.domain -eq $Domain }).'OrgID' | Select-Object -Unique
    }
    write-output "             Uploading Secure Score for $($score.TenantName) into IT-Glue"
    foreach ($org in $orgID) {
        $ExistingFlexAsset = (Get-ITGlueFlexibleAssets -filter_flexible_asset_type_id $FilterID.id -filter_organization_id $org).data | Where-Object { $_.attributes.traits.tenantid -eq $score.TenantID }
        #If the Asset does not exist, we edit the body to be in the form of a new asset, if not, we just upload.
        if (!$ExistingFlexAsset) {
            if ($FlexAssetBody.attributes.'organization-id') {
                $FlexAssetBody.attributes.'organization-id' = $org
            }
            else {
                $FlexAssetBody.attributes.add('organization-id', $org)
                $FlexAssetBody.attributes.add('flexible-asset-type-id', $FilterID.id)
            }
            write-output "                      Creating new secure score for $($score.TenantName) into IT-Glue organisation $org"
            New-ITGlueFlexibleAssets -data $FlexAssetBody

        }
        else {
            write-output "                      Updating secure score $($score.TenantName) into IT-Glue organisation $org"
            $ExistingFlexAsset = $ExistingFlexAsset | select-object -Last 1
            Set-ITGlueFlexibleAssets -id $ExistingFlexAsset.id  -data $FlexAssetBody
        }

    }
}

