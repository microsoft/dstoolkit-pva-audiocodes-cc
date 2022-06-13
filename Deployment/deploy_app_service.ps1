#Requires -Version 6

Param(
    [string] $name,
    [string] $resourceGroup,
    [string] $showCommands = "false", 
    [string] $logfile = $(Join-Path $PSScriptRoot "deploy_log.txt" -Resolve)
 )

# Create App Service Plan for Azure Function
$appServicePlanName = $name
Write-Host "Creating a dedicated App Service Plan used by the mock customer service Function App so its always on" -NoNewline -ForegroundColor Green
if ($showCommands.ToLower() -eq "true") { Write-Host ""; Write-Host "az functionapp plan create --name ""$appServicePlanName"" --resource-group ""$resourceGroup --location ""$location"" --sku B1 " -NoNewline }
az functionapp plan create `
  --name "$appServicePlanName" `
  --resource-group "$resourceGroup" `
  --location "$location" `
  --sku B1 `
  2>> "$logFile" | Out-Null
  Write-Host " - Done." -ForegroundColor Green

# Create return object
$result = [PSCustomObject]@{
  appServicePlanName = $appServicePlanName
}

return $result | ConvertTo-Json
