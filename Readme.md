# Azure FrontDoor & Azure Container Apps

## Overview
This repository demonstrates how to use Azure Container Apps with private VNET integration together with Azure FrontDoor. This follows the best practice to enable only VNET internal incoming traffic to Azure Container Apps.

## Architecture
![Architecture](./assets/architecture.png "Azure Architecture")

## Implementation
This project contains two main packages.

### App
The example app is a nodeJS application, that consists of an index.html (/) and an health endpoint (/health). The app is already pre-built and publicly available on Docker Hub.

### Infrastructure
This repo leverages Bicep as Infrastructure as Code. Beside the provisioning of the resource group and approving of the created private link connection everything is deployed by Bicep code.
Entrypoint for the deployment is deploy.sh. It is crucial to define the basename in the deploy.sh before running it. This base name is used as a prefix for all resources, including the resource group.

## Setup / How To
### Prerequisites (Local)
1. Azure Subscription
2. Azure CLI installed locally, Azure Cloud Shell or GitHub Codespaces (or alternatives)
3. Bash shell to execute deploy.sh
4. jq is locally required to read outputs

### Deployment (Local)
1. App is already built and available on Docker Hub. Feel free to re-build and host it yourself. (/app)
2. Infrastructure code is in /infra

```
# Update Base_Name to an individual value in /infra/deploy.sh. 
## (Optional: Update location)

cd infra

az login
az upgrade 
./deploy.sh
```
3. After 10-15 minutes everything should be deployed and the FrontDoor Endpoint is reachable. The "Hello Container App"-application is available.

### Deployment (GitHub Actions)
1. Clone/Fork Repo to your own GitHub repository
2. App is already built and available on Docker Hub. Feel free to re-build yourself. (Run GitHub Action: *(Optional) Build "Hello World" Container App*)
3. Azure Subscription
4. Add a Service Principal Secret to GitHub Secrets as AZURE_CREDENTIALS (HowTo: https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure#create-a-service-principal)
5. Deploy Infrastructure (Run GitHub Action: *Deploy FrontDoor w/ Container Apps*)
6. Get the FQDN to your app out of the "Final Outputs"-step or check the FrontDoor resource

## Result
After the deployment a basic Azure Container App application is available via Azure FrontDoor FQDN.
![Website in Browser](./assets/result.png "Hello Container Apps")

## Limitations / Improvements
- Private Link Service Auto Approval is not possible because the FrontDoor service is located in a Microsoft owned subscription. For that reason, this project tries to approve the endpoint semi-automatic. In some scenarios this might fail, and you need to approve the request manually in the created Private Link Service after the deployment.
- The approach of this repo does not work with the new Azure Container Apps Workload Profiles feature. Currently, there is no IP-based load balancer when using workload profiles. In this scenario, you have to add an Azure Application Gateway in front of Azure Container Apps and use the Application Gateway as a FrontDoor backend. See [GitHub - ACA Feature Request](https://github.com/microsoft/azure-container-apps/issues/402#issuecomment-1599437712)
- (Optional) Include Custom Domains

# Disclaimer
Please note that this code is for demonstration purposes and not supported by Microsoft for production use! The recommended way to deploy this solution is to use an Application Gateway between Frontdoor and Azure Container Apps.