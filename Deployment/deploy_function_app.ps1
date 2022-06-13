#Requires -Version 6

Param(
    [string] $name,
    [string] $resourceGroup,
    [string] $storageAccountName,
    [string] $functionAppServicePlanName,
    [string] $appInsightsName,
    [string] $showCommands = "false",
    [string] $logfile = $(Join-Path $PSScriptRoot "deploy_log.txt" -Resolve)
 )

# Create Azure Function
$functionAppName = $name
Write-Host "Creating the mock customer service Function App" -NoNewline -ForegroundColor Green
if ($showCommands.ToLower() -eq "true") { Write-Host ""; Write-Host "az functionapp create --name ""$functionAppName"" --resource-group ""$resourceGroup"" --storage-account ""$storageAccountName"" --plan ""$functionAppServicePlanName"" --functions-version ""3"" " -NoNewline }
az functionapp create `
    --name "$functionAppName" `
    --resource-group "$resourceGroup" `
    --storage-account "$storageAccountName" `
    --plan "$functionAppServicePlanName" `
    --app-insights "$appInsightsName" `
    --functions-version "3" `
    3>&1 2>&1 >> $logFile | Out-Null
Write-Host " - Done." -ForegroundColor Green

# Added this to see if it gets rid of "WARNING: Setting SCM_DO_BUILD_DURING_DEPLOYMENT to false"
# See this link for details: https://docs.microsoft.com/en-us/azure/azure-functions/functions-deployment-technologies#remote-build-on-linux
#$env:ENABLE_ORYX_BUILD = "true"
#$env:SCM_DO_BUILD_DURING_DEPLOYMENT = "true"

# Publish the Function App code
$projectDirectoryForFunctionApp = Join-Path -Path $PSScriptRoot -ChildPath "..\ContosoCustomerService" -Resolve
$publishFolder = "$projectDirectoryForFunctionApp\bin\Release\netcoreapp3.1\publish"

Write-Host "Publishing the mock customer service Function App code to local folder so it can be zipped" -NoNewline -ForegroundColor Green
if ($showCommands.ToLower() -eq "true") { Write-Host ""; Write-Host "dotnet publish -c Release ""$projectDirectoryForFunctionApp"" " -NoNewline }
dotnet publish `
    -c Release `
    "$projectDirectoryForFunctionApp" `
    3>&1 2>&1 >> $logFile | Out-Null
Write-Host " - Done." -ForegroundColor Green

# Create Function App deployment zip file
$publishZip = "CustomerServicePublish.zip"
Write-Host "Creating the mock customer service Function App deployment zip file" -NoNewline -ForegroundColor Green
if ($showCommands.ToLower() -eq "true") { Write-Host ""; Write-Host "[io.compression.zipfile]::CreateFromDirectory(""$publishFolder"", ""$publishZip"")" -NoNewline }

if (Test-path $publishZip) { 
    Remove-item "$publishZip" 2>> "$logFile" | Out-Null 
}

#Add-Type -assembly "system.io.compression.filesystem"
[io.compression.zipfile]::CreateFromDirectory("$publishFolder", "$(Join-Path $PSScriptRoot $publishZip)") `
    3>&1 2>&1 >> $logFile | Out-Null
Write-Host " - Done." -ForegroundColor Green

# Deploy Function App zipped package
Write-Host "Deploying the mock customer service Function App zipped package" -NoNewline -ForegroundColor Green
if ($showCommands.ToLower() -eq "true") { Write-Host ""; Write-Host "az functionapp deployment source config-zip -g ""$resourceGroup"" -n ""$functionAppName"" --src ""$publishZip"" " -NoNewline }
az functionapp deployment source config-zip `
    -g "$resourceGroup" `
    -n "$functionAppName" `
    --src "$publishZip" `
    3>&1 2>&1 >> $logFile | Out-Null
Write-Host " - Done." -ForegroundColor Green

# Create application settings for Function App (there aren't any app settings for the mock services but if that changes this is how we will create them)
#Write-Host "Creating the mock customer service application settings for Function App" -NoNewline -ForegroundColor Green
#if ($showCommands.ToLower() -eq "true") { Write-Host ""; Write-Host "az functionapp config appsettings set -n ""$functionAppName"" -g ""$resourceGroup"" --settings ""setting1= ""[setting1 value] ""setting2= ""[setting2 value]"" " -NoNewline }
#az functionapp config appsettings set -n $functionAppName -g $resourceGroup --settings `
#    "setting1= " `
#    "setting2= " `
#    2>> "$logFile" | Out-Null
#Write-Host " - Done." -ForegroundColor Green

# Set a development usage quota limit (in GB's) to address DOS attacks or run-away compute
Write-Host "Setting a development usage quota on the mock customer service Function App - remove or modify this seeting if you turn this mock service into a real service and deploy it to production" -NoNewline -ForegroundColor Green
if ($showCommands.ToLower() -eq "true") { Write-Host ""; Write-Host "az functionapp update -g ""$resourceGroup"" -n ""$functionAppName"" --set ""dailyMemoryTimeQuota=50000"" " -NoNewline }
az functionapp update `
    -g "$resourceGroup" `
    -n "$functionAppName" `
    --set "dailyMemoryTimeQuota=50000" `
    3>&1 2>&1 >> $logFile | Out-Null
Write-Host " - Done." -ForegroundColor Green

# Create return object
$result = [PSCustomObject]@{
  functionAppName = $functionAppName
}

return $result | ConvertTo-Json
