#!/bin/bash
# Cloud deployment script for FastAPI backend (Azure App Service example)
# Prerequisites: Azure CLI, Docker, Python 3.9+

RESOURCE_GROUP="zt-dashboard-rg"
APP_NAME="zt-dashboard-api"
LOCATION="eastus"
DOCKER_IMAGE="zt-dashboard-api:latest"

# Build Docker image
az acr create --resource-group $RESOURCE_GROUP --name ztdashboardacr --sku Basic --location $LOCATION
az acr build --registry ztdashboardacr --image $DOCKER_IMAGE .

# Create App Service plan and web app
az appservice plan create --name $APP_NAME-plan --resource-group $RESOURCE_GROUP --sku B1 --is-linux --location $LOCATION
az webapp create --resource-group $RESOURCE_GROUP --plan $APP_NAME-plan --name $APP_NAME --deployment-container-image-name ztdashboardacr.azurecr.io/$DOCKER_IMAGE

# Configure environment variables
az webapp config appsettings set --resource-group $RESOURCE_GROUP --name $APP_NAME --settings DASHBOARD_SECRET="your-production-secret"

# Enable HTTPS only
az webapp update --resource-group $RESOURCE_GROUP --name $APP_NAME --set httpsOnly=true

# Output endpoint
ENDPOINT=$(az webapp show --resource-group $RESOURCE_GROUP --name $APP_NAME --query defaultHostName -o tsv)
echo "Backend deployed at: https://$ENDPOINT"
