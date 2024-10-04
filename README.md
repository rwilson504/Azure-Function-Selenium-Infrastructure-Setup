# Azure Function Selenium Infrastructure Setup

## Project Overview

This project sets up the necessary infrastructure to run **Azure Functions** that use **Selenium** hosted in an **Azure Container Instance (ACI)**. It automates the deployment process, provisioning all the required Azure resources and registering the Azure AD Application, allowing users to easily deploy an Azure Function capable of running Selenium browser automation tasks in the cloud.

## Goals

- Provide an infrastructure setup that allows Azure Functions to execute **Selenium-based** automation tasks.
- Use **Azure Container Instances (ACI)** to host the Selenium grid for scalable browser automation.
- Ensure the setup integrates securely with **Azure Active Directory (Azure AD)** for authentication.
- Secure network communication between the Azure Function and ACI by isolating resources within a **Virtual Network (VNet)**.

## Network Architecture

The deployment creates a **Virtual Network (VNet)** with two subnets:

1. **Function Subnet**: Hosts the **Azure Function App**. This subnet is publicly accessible, allowing the function to receive HTTP requests over the internet. At the same time, it has VNet Integration enabled to securely access resources within the VNet.
2. **Container Subnet**: Hosts the **Azure Container Instance (ACI)**, which runs Selenium. This subnet is isolated from the public internet, allowing access only from the Function Subnet through the VNet. This setup ensures that only the Azure Function can access the ACI, creating a secure communication channel for internal use.

### Network Security

- **Network Security Groups (NSGs)** restrict traffic between the subnets:
  - The **Container Subnet** allows inbound traffic only from the **Function Subnet**.
  - Public access to the **Container Subnet** is completely restricted, isolating it from external networks.

## Deployment

To deploy this project, you need to run the `deploy.ps1` PowerShell script, which automates the entire infrastructure setup. Below is a summary of the script's functionality:

### What `deploy.ps1` Does

1. **Logs into Azure and Microsoft Graph**: Depending on the environment (e.g., **Global**, **USGov**, **USGovDoD**), the script authenticates the user with the required permissions in both Azure and Microsoft Graph.

2. **Creates an Azure AD Application**: An Azure AD Application is registered using Microsoft Graph, which is necessary for the Azure Function App to authenticate and run securely.

3. **Generates a Client Secret**: A client secret is created for the Azure AD Application and is stored securely in the Azure Key Vault.

4. **Creates a Resource Group**: The script sets up an Azure Resource Group where all the resources, including the Azure Function App, the container instance, and other resources, will be deployed.

5. **Deploys a Bicep Template**: The Bicep template provisions the necessary Azure resources, including the **Azure Function App** and **Azure Container Instance** using the provided Selenium container image.

6. **Configures Redirect URIs**: Adds the necessary redirect URIs to the Azure AD Application for authentication purposes.

7. **Deploys a Test Function**: A basic test function is deployed to the Azure Function App, which you can later replace with your specific Selenium-based automation logic.

## How to Run the Deployment Script

### Requirements

- PowerShell environment with the following modules installed:
  - **Az.Accounts**
  - **Az.Resources**
  - **Microsoft.Graph**

You can install the necessary modules by running the following PowerShell commands:

```powershell
Install-Module -Name Az.Accounts -Scope CurrentUser
Install-Module -Name Az.Resources -Scope CurrentUser
Install-Module -Name Microsoft.Graph -Scope CurrentUser
```

### Running the Script

To run the `deploy.ps1` script, open PowerShell and navigate to the folder containing the script. Then, run the following command:

```powershell
./deploy.ps1 -ApplicationName "YourAppName" -ResourceGroupName "YourResourceGroup" -Location "YourAzureRegion"
```

#### Parameters

- **ApplicationName**: The name for both the Azure AD Application and the Azure Function App. This must be between 3 and 14 characters.
- **ResourceGroupName**: The name of the Azure Resource Group where all resources will be deployed. Must be between 1 and 90 characters.
- **Location**: The Azure region where resources will be deployed (e.g., `eastus`, `westus`, `usgovvirginia`).
- **Environment**: Defines the Azure environment, such as `Global`, `USGov`, or `USGovDoD`. Defaults to `Global`.
- **SeleniumImage**: The container image to use for the Selenium Grid. Defaults to `selenium/standalone-edge`.
- **SeleniumImageTag**: The tag for the Selenium container image. Defaults to `latest`.

### Example

```powershell
./deploy.ps1 -ApplicationName "RAWSELAPP" -ResourceGroupName "RAWSELGROUP" -Location "eastus"
```

This command will deploy the infrastructure to **East US** with an application name of **RAWSELAPP**.

## Notes

- The script is designed to be flexible, allowing users to specify different container images and Azure environments.
- The deployment includes a test function that runs Selenium in an **Azure Container Instance** for demonstration purposes. You can modify or replace this function with your specific Selenium-based automation logic.

## Next Steps

After successfully running the deployment script, you can navigate to the deployed Azure Function App and test the Selenium setup. You can also extend the test function to perform more complex tasks based on your automation needs.
