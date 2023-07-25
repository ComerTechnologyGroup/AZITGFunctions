<#
.SYNOPSIS
<Overview of script>
.DESCRIPTION
<Brief description of script>
.NOTES
   Version:				0.1
   Author:				qcomer (https://github.com/qcomer)
   Last Modified:		Fri Mar 24 2023
   Modified By:			qcomer
   Date Created:		Thu Mar 23 2023
   Filename:			run.ps1
HISTORY:
Date      		          By      		Comments
----------		         ----------		--------------------------------------------

LICENSE: MIT License

Copyright (c) 2023 Comer Technology Group (CTG)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

#>

#region Variables

#$script:LogPath = "C:\windows\temp\"
#$script: LogName         = script_name
$Script:S1Token          = '5ggHIkwNZn7qminUtOKFWo5CpdVyqvt4oUspWcLDDD86Xg27L5le96PPZRMdCE964XL5TjAHZwgqPQlX'
$Script:s1url            = 'https://usea1-pax8-exsp.sentinelone.net'
$script:AutomateUrl      = 'https://stradiant.hostedrmm.com'
$script:AutomateUserName = 'PSIntegrations'
$script:AutomatePassword = 'vh!,K8mY5+t{%Lsl,v2j'
$script:AutomateClientId = 'b16a31d0-c78e-4954-a7c7-6fe073bd4275'



[pscredential]$script:AutomateCredentials = New-Object System.Management.Automation.PSCredential($script:AutomateUserName, (ConvertTo-SecureString -String $script:AutomatePassword -AsPlainText -Force))

Connect-ControlAPI -Credential $script:AutomateCredentials -ClientId $script:AutomateClientId -Server 'https://stradiant.hostedrmm.com:8040'
#endregion Variables

#region Modules
If (-not(Get-Module -Name AutomateAPI)) {
    Install-Module -Name AutomateAPI -Force -AllowClobber
}
Import-Module -Name AutomateAPI
#endregion Modules

Connect-AutomateAPI -server $(($script:AutomateUrl).split('//')[1]) -Credential $script:AutomateCredentials -ClientId $script:AutomateClientId

#region Functions

function Invoke-SentinelWebRequest {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Server,
        [Parameter()]
        [String]
        $APIToken,
        [Parameter()]
        [String]
        $Target
    )
    $global:Headers = @{
        'Authorization' = "ApiToken $APIToken"
        'Content-Type'  = 'application/json'
    }
    $BaseURL = "$Server/web/api/v2.1/"
    if (-not($BaseURL.endsWith('/'))) {
        $BaseURL += '/'
    }
    if (-not([string]::IsNullOrEmpty($target))) {
        $URL = "$BaseURL$Target"
    } else {
        $URL = $BaseURL
    }
    $Response = Invoke-WebRequest -Uri $URL -Method 'GET' -Headers $global:Headers
   $Response = $Response.Content | ConvertFrom-Json
    return $response
}

function Get-s1Accounts {
    <#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER
    Parameter description
    .EXAMPLE
    An example
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        [Parameter(mandatory = $false, position = 0, valuefrompipeline = $true)]
        [string]
        $Param1
    )
    begin {

    }
    process {

    }
    end {

    }
}

#endregion Functions

# Input bindings are passed in via param block.
param($Timer)
$SiteTokens = Get-AutomateClient -AllClients | ForEach-Object { Get-AutomateClientExtraFields -ClientId $_.id -Title 'SentinelOne Sitekey' -ValueOnly $true }
foreach ($site in $sitetokens) {
    Invoke-SentinelWebRequest -Server $script:s1url -APIToken $Script:S1Token -Target "sites?registrationToken=$site" | select -ExpandProperty data | Select -ExpandProperty sites
}
# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host 'PowerShell timer is running late!'
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
