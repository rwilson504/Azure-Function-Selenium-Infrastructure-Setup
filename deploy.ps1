<#
    .SYNOPSIS
    This script deploys an Azure Function App and registers an Azure AD Application.

    .DESCRIPTION
    The script performs the following tasks:
    1. Logs into Azure and Microsoft Graph (based on the environment selected).
    2. Creates an Azure AD Application using Microsoft Graph.
    3. Creates a client secret for the Azure AD Application.
    4. Creates a Resource Group in Azure.
    5. Deploys a Bicep template for an Azure Function App using the provided container image.
    6. Adds a redirect URI to the Azure AD Application.
    7. Deploys a test function to the Azure Function App

    .PARAMETER ApplicationName
    The name of the Azure AD Application and the Azure Function App. Must be between 3 and 14 characters.

    .PARAMETER ResourceGroupName
    The name of the Azure Resource Group to deploy the resources. Must be between 1 and 90 characters.

    .PARAMETER Location
    The Azure location where resources will be deployed (e.g., eastus, westus, usgovvirginia).

    .PARAMETER Environment
    Defines the Azure environment: Global, USGov, or USGovDoD. Defaults to Global.

    .PARAMETER SeleniumImage
    The container image to use for the Azure Function App. Defaults to "selenium/standalone-edge".

    .PARAMETER SeleniumImageTag
    The container image tag to use for the Azure Function App. Defaults to "latest".

    .NOTES
    Author: Your Name
    Date: <Date>

    .EXAMPLE
    ./deploy.ps1 -ApplicationName "RAWSELAPP" -ResourceGroupName "RAWSELGROUP" -Location "eastus"

    .REQUIREMENTS
    Requires the following PowerShell modules:
    1. Az.Accounts
    2. Az.Resources
    3. Microsoft.Graph

#>

param (
    [Parameter(Mandatory = $true)]
    [ValidateLength(3, 14)]
    [string]$ApplicationName,  # Ensure that the application name is between 3 and 14 characters long
    
    [Parameter(Mandatory = $true)]
    [ValidateLength(1, 90)]
    [string]$ResourceGroupName,  # Resource Group Name is mandatory

    [Parameter(Mandatory = $true)]
    [string]$Location,  # Location is mandatory
    
    [Parameter()]
    [ValidateSet('Global', 'USGov', 'USGovDoD')]
    [string] $Environment = "Global",  # Optional, defaults to Global
    
    [string]$SeleniumImage = "selenium/standalone-edge",  # Optional container image
    [string]$SeleniumImageTag = "latest"  # Optional container image tag
)

# Define the mapping between Connect-MgGraph environments and Get-AzAccount environments
$environmentMap = @{
    "Global"   = "AzureCloud"
    "USGov"    = "AzureUSGovernment"
    "USGovDoD" = "AzureUSGovernment"  # Both map to the same Azure US Government cloud for Azure operations
}

# Function to map the Graph environment to the Azure environment
function Get-AzureEnvironmentFromGraph {
    param (
        [string]$GraphEnvironment
    )
    
    if ($environmentMap.ContainsKey($GraphEnvironment)) {
        return $environmentMap[$GraphEnvironment]
    } else {
        throw "Unknown Microsoft Graph environment: $GraphEnvironment"
    }
}

# Function to check if the user is logged in to Azure and Microsoft Graph
function Test-AzureLogin {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "You are not logged in to Azure. Please log in."

        # Map the Graph environment to the corresponding Azure environment
        $azureEnvironment = Get-AzureEnvironmentFromGraph -GraphEnvironment $Environment
        Connect-AzAccount -Environment $azureEnvironment        
    } else {
        Write-Host "You are already logged in to Azure as: $($context.Account)"
    }

    # Check if user is logged into Microsoft Graph
    $graphContext = Get-MgContext
    if (-not $graphContext) {
        Write-Host "You are not logged in to Microsoft Graph. Please log in."
        $token = (ConvertTo-SecureString -String (Get-AzAccessToken -ResourceTypeName MSGraph).Token -AsPlainText -Force)
        # Connect to Microsoft Graph based on the selected environment
        Connect-MgGraph -AccessToken $token -Environment $Environment        
    } else {
        Write-Host "You are already logged in to Microsoft Graph."
    }
}

# Call the function to check and log in if needed
Test-AzureLogin

$appServicePlanName = "${ApplicationName}ASP"
$storageAccountName = "${ApplicationName}storage"
$keyVaultName = "${ApplicationName}keyVault"

# Define the path to the Bicep folder and the Bicep file
$bicepFolderPath = "bicep"
$bicepFilePath = Join-Path (Get-Location) $bicepFolderPath "main.bicep"

# Verify if the Bicep file exists
if (-not (Test-Path $bicepFilePath)) {
    Write-Host "Bicep file not found at path: $bicepFilePath" -ForegroundColor Red
    exit
}

# Create the App Registration using Microsoft Graph
Write-Host "Creating Azure AD App Registration: $ApplicationName..."
$appRegistration = New-MgApplication -DisplayName $ApplicationName -SignInAudience "AzureADMyOrg"

# Capture the App Registration details
$clientId = $appRegistration.AppId
$tenantId = (Get-AzContext).Tenant.Id

Write-Host "App Registration created successfully."
Write-Host "Client ID: $clientId"
Write-Host "Tenant ID: $tenantId"

# Create a client secret for the App Registration using Microsoft Graph
Write-Host "Creating client secret for the App Registration..."
$password = Add-MgApplicationPassword -ApplicationId $appRegistration.Id -PasswordCredential @{DisplayName = "MyAppSecret"}

# Convert the plain-text client secret to SecureString for use in deployment
$secureClientSecret = ConvertTo-SecureString -String $password.SecretText -AsPlainText -Force

# Validate the location in Azure
$locations = Get-AzLocation | Select-Object Location, DisplayName
if (-not ($locations.Location -contains $Location)) {
    Write-Host "Invalid location entered. Please run the script again and choose a valid location."
    exit
}

# Create the Resource Group in Azure
Write-Host "Creating Resource Group: $ResourceGroupName in $Location..."
New-AzResourceGroup -Name $ResourceGroupName -Location $Location

# Deploy the Bicep file with parameters
Write-Host "Deploying Bicep file to Resource Group: $ResourceGroupName from path: $bicepFilePath..."
$deployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $bicepFilePath `
    -location $Location `
    -functionAppName $ApplicationName `
    -appServicePlanName $appServicePlanName `
    -storageAccountName $storageAccountName `
    -SeleniumImage $SeleniumImage `
    -SeleniumImageTag $SeleniumImageTag `
    -clientId $clientId `
    -keyVaultName $keyVaultName `
    -clientSecret $secureClientSecret

# Add a redirect URI to the App Registration using Microsoft Graph
$redirectUri = "https://$($deployment.Outputs.functionAppDefaultHostName.Value)/.auth/login/aad/callback"
Write-Host "Adding redirect URI: $redirectUri to the App Registration..."
Update-MgApplication -ApplicationId $appRegistration.Id -Web @{
    RedirectUris = @($redirectUri)
    ImplicitGrantSettings = @{
        EnableIdTokenIssuance = $true
    }
}

# deploy test function
func azure functionapp publish $ApplicationName --csharp

# Check deployment status
if ($deployment.ProvisioningState -eq "Succeeded") {
    Write-Host "Deployment succeeded!"
} else {
    Write-Host "Deployment failed!"
    Write-Host $deployment
}
