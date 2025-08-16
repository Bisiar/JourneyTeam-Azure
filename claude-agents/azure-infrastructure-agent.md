# Azure Infrastructure Agent

## Purpose
Enforce Azure naming conventions and generate properly named Bicep templates for `azd up` deployments.

## Azure Naming Conventions

### Resource Abbreviations (Microsoft Standards)
```yaml
resource_group: rg-
app_service: app-
app_service_plan: plan-
function_app: func-
storage_account: st     # lowercase, no hyphens, 3-24 chars
key_vault: kv-
sql_server: sql-
sql_database: sqldb-
cosmos_db: cosmos-
service_bus: sb-
event_hub: evh-
api_management: apim-
container_registry: cr
aks_cluster: aks-
vm: vm-
vnet: vnet-
subnet: snet-
nic: nic-
nsg: nsg-
public_ip: pip-
load_balancer: lb-
application_gateway: agw-
```

### Naming Pattern
`{resource-type}-{workload}-{environment}-{region}-{instance}`

### Examples for Project "test-project"
```
rg-test-project-dev-eastus-001
app-test-project-prod-001
stestprojectprod001  # storage (no hyphens)
kv-test-project-dev
sqldb-test-project-prod
```

## Bicep Template Generation

### Main Template Structure
```bicep
// infra/main.bicep
targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the project/workload')
param projectName string

@allowed(['dev', 'test', 'prod'])
@description('Environment name')
param environment string = 'dev'

@description('Primary location for all resources')
param location string = 'eastus'

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, projectName, environment, location))

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourceGroup}${projectName}-${environment}-${location}'
  location: location
}

// App Service Plan
module appServicePlan './modules/app-service-plan.bicep' = {
  name: 'appServicePlan'
  scope: rg
  params: {
    name: '${abbrs.appServicePlan}${projectName}-${environment}'
    location: location
    sku: environment == 'prod' ? 'P1v2' : 'B1'
  }
}
```

### Abbreviations File
```json
// infra/abbreviations.json
{
  "resourceGroup": "rg-",
  "appService": "app-",
  "appServicePlan": "plan-",
  "functionApp": "func-",
  "storageAccount": "st",
  "keyVault": "kv-",
  "sqlServer": "sql-",
  "sqlDatabase": "sqldb-",
  "cosmosDb": "cosmos-",
  "serviceBus": "sb-",
  "eventHub": "evh-"
}
```

## Validation Rules

### Storage Account Names
```javascript
function validateStorageAccountName(name) {
  const rules = {
    minLength: 3,
    maxLength: 24,
    pattern: /^[a-z0-9]+$/,
    globallyUnique: true
  };
  
  // Remove hyphens and convert to lowercase
  const cleanName = name.replace(/-/g, '').toLowerCase();
  
  if (cleanName.length < rules.minLength || cleanName.length > rules.maxLength) {
    throw new Error(`Storage account name must be 3-24 characters`);
  }
  
  if (!rules.pattern.test(cleanName)) {
    throw new Error(`Storage account name can only contain lowercase letters and numbers`);
  }
  
  return cleanName;
}
```

## Azure Developer CLI Integration

### azure.yaml Configuration
```yaml
# azure.yaml
name: test-project
metadata:
  template: azure-waf-compliant
services:
  web:
    project: ./src/Web
    language: csharp
    host: appservice
  api:
    project: ./src/Api
    language: csharp
    host: functions
infra:
  provider: bicep
  path: infra
  module: main
```

### Deployment Command
```bash
# Deploy with proper naming
azd up --environment dev --location eastus
```

## Integration with Other Agents

### With Documentation Agent
- Update `DEPLOYMENT.md` with resource names
- Document naming conventions used

### With Architecture Agent
- Ensure infrastructure code follows IaC patterns
- Validate separation of concerns

### With Audit Agent
- Generate evidence of naming compliance
- Document resource governance

## Example Prompt
```
claude "As the Azure Infrastructure Agent, create Bicep templates for a project called 'customer-portal' with proper Azure naming conventions. Include app service, SQL database, and storage account. Make it ready for 'azd up' deployment."
```

## Validation Script
```bash
#!/bin/bash
# validate-naming.sh

PROJECT_NAME="$1"
ENVIRONMENT="$2"

# Validate resource group name
RG_NAME="rg-${PROJECT_NAME}-${ENVIRONMENT}-eastus"
if [[ ! "$RG_NAME" =~ ^rg-[a-z0-9-]{1,90}$ ]]; then
  echo "❌ Invalid resource group name: $RG_NAME"
  exit 1
fi

# Validate storage account name
STORAGE_NAME="st${PROJECT_NAME}${ENVIRONMENT}001"
STORAGE_NAME=$(echo "$STORAGE_NAME" | tr -d '-' | tr '[:upper:]' '[:lower:]')
if [[ ${#STORAGE_NAME} -gt 24 ]] || [[ ! "$STORAGE_NAME" =~ ^[a-z0-9]{3,24}$ ]]; then
  echo "❌ Invalid storage account name: $STORAGE_NAME"
  exit 1
fi

echo "✅ All resource names valid"
```