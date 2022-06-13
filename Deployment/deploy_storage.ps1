#Requires -Version 6

Param(
    [string] $name,
    [string] $resourceGroup,
    [string] $location,
    [string] $showCommands = "false",
    [string] $logfile = $(Join-Path $PSScriptRoot "deploy_log.txt" -Resolve)
 )

# Create Storage account for Fucntion App
# Storage names must be between 3 and 24 characters long and use numbers and lower-case letters only
$storageAccountName = $name.ToLower()
Write-Host "Creating the Storage Account for customer service Function App and audio logos" -NoNewline -ForegroundColor Green
if ($showCommands.ToLower() -eq "true") { Write-Host ""; Write-Host "az storage account create -n ""$storageAccountName"" -l ""$location"" -g ""$resourceGroup"" --sku ""Standard_LRS"" " -NoNewline }
az storage account create `
  -n "$storageAccountName" `
  -l "$location" `
  -g "$resourceGroup" `
  --allow-blob-public-access true `
  --sku "Standard_LRS" `
  2>> "$logFile" | Out-Null
Write-Host " - Done." -ForegroundColor Green

# Grab connection string 
Write-Host "Grab connection string for the Storage Account" -NoNewline -ForegroundColor Green
if ($showCommands.ToLower() -eq "true") { Write-Host ""; Write-Host "az storage account show-connection-string -g ""$resourceGroup"" -n ""$storageAccountName"" " -NoNewline }
$storageConnectionString = az storage account show-connection-string -g "$resourceGroup" -n "$storageAccountName" | ConvertFrom-Json -Depth 10
Write-Host " - Done." -ForegroundColor Green

# Create return object
$result = [PSCustomObject]@{
  storageAccountName = $storageAccountName
  storageConnectionString = $storageConnectionString.connectionString
}

return $result | ConvertTo-Json
