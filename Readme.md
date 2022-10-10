# Azure FrontDoor & Azure Container Apps

## Overview
This repository demonstrates how to use Azure Container Apps with private VNET integration together with Azure FrontDoor. This follows the best practise to enable only VNET internal incoming traffic to Azure Container Apps.

## Architecture
![Architecture](./assets/architecture.png "Azure Architecture")

## Implementation
This project contains two main packages.

### App
The example app is a nodeJS application, that consists of an index.html (/) and an health endpoint (/health). The app is already pre-built and publicly available in Docker Hub.

### Infrastructure
This repo leverages Bicep as Infrastructure as Code. Beside the provisioning of the resource group and approving of the created private link connection everything is deployed by Bicep code.
Entrypoint for the deployment is deploy.sh. It is crucial to define the basename in the deploy.sh before running it. This base name is used as a prefix for all resources, including the resource group.

## Result
After the deployment a basic Azure Container App application is available via Azure FrontDoor FQDN.
![Website in Browser](./assets/result.png "Hello Container Apps")

## Limitations / Improvements
- Documentation needs improvement
- GitHub Actions integration missing
- (Optional) Include Custom Domains