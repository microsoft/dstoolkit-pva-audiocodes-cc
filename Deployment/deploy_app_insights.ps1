#Requires -Version 6

Param(
    [string] $name,
    [string] $resourceGroup,
    [string] $showCommands = "false",
    [string] $logfile = $(Join-Path $PSScriptRoot "deploy_log.txt" -Resolve)
 )

# Create App Insights instance for the Azure Function
$appInsightsName = $name
Write-Host "Creating the App Insights instance used by the ACS Agent Hub Function App" -NoNewline -ForegroundColor Green
if ($showCommands.ToLower() -eq "true") { Write-Host ""; Write-Host "az resource create -g ""$resourceGroup"" -n ""$appInsightsName"" --resource-type ""Microsoft.Insights/components"" --properties '{\"Application_Type\":\"web\"}' " -NoNewline }
az resource create `
  -g "$resourceGroup" `
  -n "$appInsightsName" `
  --resource-type "Microsoft.Insights/components" `
  --properties '{\"Application_Type\":\"web\"}' `
  2>> "$logFile" | Out-Null
Write-Host " - Done." -ForegroundColor Green

# Create return object
$result = [PSCustomObject]@{
  appInsightsName = $appInsightsName
}

return $result | ConvertTo-Json
