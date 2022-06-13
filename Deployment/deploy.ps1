<# 
This is a multi-line comment syntax
#>

#Requires -Version 6

Param(
    [string] $name,
    [string] $resourceGroup,
    [string] $location,
    [string] $showCommands = "false",
    [string] $logFile = "deploy_log.txt"
)

# Get timestamp
$startTime = Get-Date

# Reset log file
if (Test-Path $logFile) {
    Clear-Content $logFile -Force | Out-Null
}
else {
    New-Item -Path $logFile | Out-Null
}

# Check for AZ CLI and confirm version
if (Get-Command az -ErrorAction SilentlyContinue) {
    $azcliversionoutput = az -v
    [regex]$regex = '(\d{1,3}.\d{1,3}.\d{1,3})'
    [version]$azcliversion = $regex.Match($azcliversionoutput[0]).value
    [version]$minversion = '2.2.0'

    if ($azcliversion -ge $minversion) {
        $azclipassmessage = "AZ CLI passes minimum version. Current version is $azcliversion"
        Write-Debug $azclipassmessage
        $azclipassmessage | Out-File -Append -FilePath $logfile
    }
    else {
        $azcliwarnmessage = "You are using an older version of the AZ CLI, `
    please ensure you are using version $minversion or newer. `
    The most recent version can be found here: http://aka.ms/installazurecliwindows"
        Write-Warning $azcliwarnmessage
        $azcliwarnmessage | Out-File -Append -FilePath $logfile
    }
}
else {
    $azclierrormessage = 'AZ CLI not found. Please install latest version.'
    Write-Error $azclierrormessage
    $azclierrormessage | Out-File -Append -FilePath $logfile
}

# Get mandatory parameters
if (-not $name) {
    $name = Read-Host "? Assistant's Name (used as default name for resource group and deployed resources)"
}

if (-not $resourceGroup) {
    $resourceGroup = $name
}

if (-not $location) {
    $location = Read-Host "? Azure resource group region"
}

# Create resource group
Write-Host "Creating resource group for the contact center mock services" -ForegroundColor Green -NoNewline
if ($showCommands.ToLower() -eq "true") { Write-Host ""; Write-Host "az group create --name ""$resourceGroup"" --location ""$location"" --output ""json"" " -NoNewline }
az group create `
  --name "$resourceGroup" `
  --location "$location" `
  --output "json" `
  2>> "$logFile" | Out-Null
Write-Host " - Done." -ForegroundColor Green

$appServicePlan = Invoke-Expression "& '$(Join-Path $PSScriptRoot 'deploy_app_service.ps1' -Resolve)' -name ""$name"" -resourceGroup ""$resourceGroup"" -showCommands ""$showCommands"" -Encoding UTF8" | ConvertFrom-Json

$appInsights = Invoke-Expression "& '$(Join-Path $PSScriptRoot 'deploy_app_insights.ps1' -Resolve)' -name ""$name"" -resourceGroup ""$resourceGroup"" -showCommands ""$showCommands"" -Encoding UTF8" | ConvertFrom-Json

$agentHubStorage = Invoke-Expression "& '$(Join-Path $PSScriptRoot 'deploy_storage.ps1' -Resolve)' -name ""$name""  -resourceGroup ""$resourceGroup"" -location ""$location"" -showCommands ""$showCommands"" -Encoding UTF8" | ConvertFrom-Json

$subscriptionId = az account show --query id --output tsv

$populationResults = Invoke-Expression "& '$(Join-Path $PSScriptRoot 'prepopulate_audiologos.ps1' -Resolve)' -name ""$name"" -resourceGroup ""$resourceGroup"" -subscriptionId ""$subscriptionId"" -storageAccount ""$($agentHubStorage.storageAccountName)"" -showCommands ""$showCommands"" -Encoding UTF8"

$functionApp = Invoke-Expression "& '$(Join-Path $PSScriptRoot 'deploy_function_app.ps1' -Resolve)' -name ""$name"" -resourceGroup ""$resourceGroup"" -storageAccountName ""$($appServicePlan.appServicePlanName)"" -functionAppServicePlanName ""$($appServicePlan.appServicePlanName)"" -appInsightsName ""$($appInsights.appInsightsName)"" -showCommands ""$showCommands"" -Encoding UTF8" | ConvertFrom-Json

$endTime = Get-Date
$duration = New-TimeSpan $startTime $endTime
Write-Host "deploy.ps1 took $($duration.seconds) seconds finish"

Write-Host "Configuration settings for the configureMockSettings Composer Topic:" -ForegroundColor Yellow
Write-Host ""
# https://contosomockservices.azurewebsites.net
Write-Host "customerServiceHostURL: https://$($functionApp.functionAppName).azurewebsites.net" -ForegroundColor Yellow
Write-Host "audioLogoURL: "$populationResults.audioLogoURL -ForegroundColor Yellow

