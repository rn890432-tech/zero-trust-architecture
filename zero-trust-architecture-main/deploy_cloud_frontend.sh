#!/bin/bash
# Cloud deployment script for dashboard frontend (Azure Storage Static Website example)
# Prerequisites: Azure CLI

RESOURCE_GROUP="zt-dashboard-rg"
STORAGE_ACCOUNT="ztdashboardstorage"
LOCATION="eastus"

# Create storage account
az storage account create --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --location $LOCATION --sku Standard_LRS

# Enable static website hosting
az storage blob service-properties update --account-name $STORAGE_ACCOUNT --static-website --index-document soc_dashboard.html --404-document soc_dashboard.html

# Upload dashboard files
az storage blob upload-batch -d '$web' -s . --account-name $STORAGE_ACCOUNT --pattern soc_dashboard.html

# Output endpoint
ENDPOINT=$(az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --query "primaryEndpoints.web" -o tsv)
echo "Frontend deployed at: $ENDPOINT"
