# AI Computer Setup Guide for macOS

This guide documents the complete AI development setup on macOS, specifically configured for JourneyTeam development workflows. This setup enables seamless integration between Claude Desktop, Azure services, and our custom MCP (Model Context Protocol) servers.

## Table of Contents

1. [Overview](#overview)
2. [Claude Desktop Installation & Configuration](#claude-desktop-installation--configuration)
3. [MCP Server Configuration](#mcp-server-configuration)
4. [Custom SherpAI MCP Server](#custom-sherpai-mcp-server)
5. [Azure Developer CLI (azd) Setup](#azure-developer-cli-azd-setup)
6. [Bicep Infrastructure as Code](#bicep-infrastructure-as-code)
7. [Credentials Management](#credentials-management)
8. [Development Workflow](#development-workflow)
9. [Troubleshooting](#troubleshooting)

## Overview

Our AI development environment consists of:
- **Claude Desktop** - AI assistant with MCP protocol support
- **Multiple MCP Servers** - Both global and project-specific tools
- **Azure Developer CLI** - For infrastructure deployment with `azd up`
- **Bicep Templates** - Infrastructure as Code for repeatable deployments
- **Integrated Credentials** - Seamless authentication across all services

## Claude Desktop Installation & Configuration

### Installation

1. **Download Claude Desktop for macOS**
   ```bash
   # Visit https://claude.ai/download and download the macOS version
   # Or use Homebrew if available
   brew install claude-desktop
   ```

2. **Initial Setup**
   - Launch Claude Desktop
   - Sign in with your Anthropic account
   - Grant necessary permissions for file access

### Configuration Location

Claude Desktop configuration is stored at:
```bash
~/Library/Application Support/Claude/claude_desktop_config.json
```

## MCP Server Configuration

Our setup includes both **global MCP servers** (available to all projects) and **project-specific servers** (like our custom SherpAI server).

### Global MCP Servers Configuration

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "telerik_blazor_assistant": {
      "command": "npx",
      "args": ["@telerik/blazor-mcp-server"],
      "env": {
        "TELERIK_API_KEY": "your-telerik-key-here"
      }
    },
    "azure-mcp-server": {
      "command": "npx",
      "args": ["@azure/mcp-server"],
      "env": {
        "AZURE_SUBSCRIPTION_ID": "your-subscription-id",
        "AZURE_TENANT_ID": "your-tenant-id"
      }
    },
    "github-mcp-server": {
      "command": "npx",
      "args": ["@github/mcp-server"],
      "env": {
        "GITHUB_TOKEN": "your-github-token"
      }
    },
    "figma-mcp-server": {
      "command": "npx",
      "args": ["@figma/mcp-server"],
      "env": {
        "FIGMA_ACCESS_TOKEN": "your-figma-token"
      }
    },
    "context7-mcp": {
      "command": "npx",
      "args": ["context7-mcp", "--key", "your-context7-key"]
    }
  }
}
```

### Installing Global MCP Servers

```bash
# Install Telerik Blazor Assistant
npm install -g @telerik/blazor-mcp-server

# Install Azure MCP Server
npm install -g @azure/mcp-server

# Install GitHub MCP Server  
npm install -g @github/mcp-server

# Install Figma MCP Server
npm install -g @figma/mcp-server

# Install Context7 MCP
npm install -g context7-mcp
```

### MCP Server Capabilities

1. **Telerik Blazor Assistant**
   - Telerik UI component documentation
   - Code examples and best practices
   - Component configuration help

2. **Azure MCP Server**
   - Azure CLI command assistance
   - Azure Developer CLI (`azd`) commands
   - Resource management and monitoring
   - Authentication methods

3. **GitHub MCP Server**
   - Repository management
   - Pull request operations
   - Issue tracking and management

4. **Figma MCP Server**
   - Design file access
   - Asset extraction
   - Design system integration

5. **Context7 MCP**
   - Context persistence across conversations
   - Session memory management

## Custom SherpAI MCP Server

We've developed a custom MCP server specifically for DevOps integration with Azure DevOps work items.

### Project Location
```bash
/Users/james/Source/jt-ops.visualstudio.com/jt-ops/jtp/jt-ai-sherpai/src/SherpAI.MCP.DevOps/
```

### Building the MCP Server

```bash
cd /Users/james/Source/jt-ops.visualstudio.com/jt-ops/jtp/jt-ai-sherpai/src/SherpAI.MCP.DevOps/
dotnet build
```

### Adding to Claude Configuration

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "sherpai-devops": {
      "command": "dotnet",
      "args": ["run"],
      "cwd": "/Users/james/Source/jt-ops.visualstudio.com/jt-ops/jtp/jt-ai-sherpai/src/SherpAI.MCP.DevOps",
      "env": {
        "AZURE_DEVOPS_PAT": "your-azure-devops-pat",
        "AZURE_DEVOPS_ORG": "https://dev.azure.com/JT-Ops",
        "AZURE_DEVOPS_PROJECT": "JourneyTeam"
      }
    }
  }
}
```

### Available Tools

Our custom MCP server provides these tools:

1. **`list_work_items`**
   - **Presets**: 'my-items', 'active-bugs', 'current-sprint'
   - **Usage**: List work items with predefined WIQL queries

2. **`get_work_item`**
   - **Parameters**: Work item ID
   - **Usage**: Get detailed information about a specific work item

3. **`query_work_items`**
   - **Parameters**: Custom WIQL query
   - **Usage**: Execute custom Work Item Query Language queries

### Usage Examples

```
"List my current sprint tasks"
"Get details of work item 12345"  
"Query active bugs assigned to me"
"Show me work items in the current iteration"
```

## Azure Developer CLI (azd) Setup

### Installation

```bash
# Install Azure Developer CLI
brew install azure/azd/azd

# Verify installation
azd version
```

### Authentication

```bash
# Login to Azure
azd auth login

# Or login with service principal
azd auth login --client-id <id> --client-secret <secret> --tenant-id <tenant>

# Set default subscription
azd env set AZURE_SUBSCRIPTION_ID "your-subscription-id"
```

### Project Initialization

For new projects:
```bash
# Initialize azd in project directory
azd init

# Set environment name
azd env new <environment-name>
```

### Key azd Commands

```bash
# Deploy everything (infrastructure + code)
azd up

# Deploy only infrastructure  
azd provision

# Deploy only application code
azd deploy

# View deployment logs
azd monitor

# Clean up resources
azd down
```

## Bicep Infrastructure as Code

Our infrastructure is defined using Azure Bicep templates for repeatable, version-controlled deployments.

### Project Structure

```
/infra/
├── main.bicep                    # Main entry point
├── main.parameters.json          # Environment parameters
├── app/                          # Application resources
│   ├── ai-foundry-hub.bicep     # AI Foundry hub
│   ├── ai-foundry-project.bicep # AI Foundry project  
│   ├── api.bicep                # API app service
│   ├── blazor.bicep             # Blazor app service
│   └── functions.bicep          # Azure Functions
├── core/                        # Core infrastructure
│   ├── ai/openai.bicep          # Azure OpenAI service
│   ├── host/appserviceplan.bicep # App Service Plan
│   ├── monitor/monitoring.bicep  # Application Insights
│   ├── search/search.bicep      # Azure AI Search
│   ├── security/keyvault.bicep  # Key Vault
│   └── storage/storage.bicep    # Storage Account
└── resources.bicep              # Resource definitions
```

### Key Bicep Features

1. **Modular Design**
   - Separate modules for different resource types
   - Reusable components across environments
   - Clear separation of concerns

2. **Parameter-Driven**
   - Environment-specific configurations
   - Secure parameter handling
   - Flexible resource naming

3. **Resource Tagging**
   - Consistent tagging strategy
   - Cost center identification
   - Environment classification

### Deployment Process

```bash
# Navigate to project root
cd /path/to/your/project

# Deploy with azd (uses Bicep automatically)
azd up

# Or deploy Bicep directly
az deployment group create \
  --resource-group rg-sherpai-dev \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.json
```

### Environment Configuration

The `.azure/<environment>/.env` file contains all environment-specific settings:

```bash
AZURE_ENV_NAME="sherpai-dev"
AZURE_LOCATION="eastus2"
AZURE_SUBSCRIPTION_ID="1c67aefd-aed5-464c-8580-8925f779a8f3"
AZURE_TENANT_ID="b59c07c6-9496-463a-ab81-77697ac73d11"
AZURE_RESOURCE_GROUP="rg-sherpai-dev"

# AI Services
AZURE_OPENAI_ENDPOINT="https://cog-sherpai-dev.openai.azure.com/"
AI_FOUNDRY_ENDPOINT="https://aiw-sherpai-dev.eastus2.api.azureml.ms"
AZURE_SEARCH_ENDPOINT="https://srch-sherpai-dev.search.windows.net"

# App Services
API_URL="https://app-api-sherpai-dev.azurewebsites.net"
BLAZOR_URL="https://app-blazor-sherpai-dev.azurewebsites.net"
FUNCTIONS_URL="https://func-sherpai-dev.azurewebsites.net"

# DevOps Integration
AZURE_DEVOPS_ORGANIZATION_URL="https://dev.azure.com/JT-Ops"
AZURE_DEVOPS_PROJECT_NAME="JourneyTeam"
```

## Credentials Management

### Azure Authentication

1. **Interactive Login** (Development)
   ```bash
   az login
   azd auth login
   ```

2. **Service Principal** (CI/CD)
   ```bash
   az login --service-principal \
     --username <client-id> \
     --password <client-secret> \
     --tenant <tenant-id>
   ```

3. **Managed Identity** (Production)
   - Automatically configured in Azure resources
   - No credentials needed in application code

### Key Vault Integration

All sensitive credentials are stored in Azure Key Vault:

```bicep
// Example Key Vault secret reference
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Application configuration references Key Vault
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: appName
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'AzureOpenAI__ApiKey'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=azure-openai-key)'
        }
      ]
    }
  }
}
```

### Environment Variables

Development credentials are managed through:

1. **Local Development**
   ```bash
   # .env files (gitignored)
   AZURE_DEVOPS_PAT="your-pat-token"
   AZURE_OPENAI_KEY="your-openai-key"
   ```

2. **Azure App Service**
   - Application Settings reference Key Vault
   - Managed Identity for Azure service access

3. **MCP Server Environment Variables**
   ```json
   {
     "env": {
       "AZURE_DEVOPS_PAT": "your-pat-from-env-or-keychain",
       "AZURE_DEVOPS_ORG": "https://dev.azure.com/JT-Ops",
       "AZURE_DEVOPS_PROJECT": "JourneyTeam"
     }
   }
   ```

### Personal Access Tokens (PAT)

For Azure DevOps integration:

1. **Create PAT in Azure DevOps**
   - Go to User Settings → Personal Access Tokens
   - Create token with Work Items (Read & Write) permissions
   - Set appropriate expiration date

2. **Secure Storage**
   - Store in macOS Keychain Access
   - Reference from environment variables
   - Never commit to source control

## Development Workflow

### Typical Development Session

1. **Start Development**
   ```bash
   # Open Claude Desktop
   open -a "Claude Desktop"
   
   # Navigate to project
   cd /path/to/project
   
   # Ensure latest dependencies
   dotnet restore
   ```

2. **Make Changes with AI Assistance**
   - Use Claude Desktop with MCP servers
   - Leverage custom DevOps tools for work item management
   - Get Azure-specific guidance from Azure MCP server

3. **Test Locally**
   ```bash
   # Build and test
   dotnet build
   dotnet test
   
   # Run locally if needed
   dotnet run --project src/YourProject.API
   ```

4. **Deploy to Azure**
   ```bash
   # Deploy everything
   azd up
   
   # Or deploy incrementally
   azd deploy
   ```

### Integration Testing Approach

Our integration tests use **real Azure services** with no mocking:

```csharp
[Fact]
public async Task DevOpsService_Should_Connect_To_Real_Azure_DevOps()
{
    // Uses real Azure DevOps connection
    var devOpsService = new DevOpsService(
        logger,
        _configuration["AzureDevOps:OrganizationUrl"]!,
        _configuration["AzureDevOps:PersonalAccessToken"]!,
        _configuration["AzureDevOps:ProjectName"]!);

    // Gets actual work items
    var workItems = await devOpsService.QueryWorkItemsAsync("my-items");
    
    // Verifies real data
    workItems.Should().NotBeEmpty();
}
```

### AI-Assisted Code Development

1. **Use MCP Tools Proactively**
   - "List my current sprint tasks" → Gets real work items
   - "Show me Azure CLI commands for Key Vault" → Azure MCP server assistance
   - "How do I configure Telerik Grid sorting?" → Telerik MCP server help

2. **Leverage Context Persistence**
   - Context7 MCP maintains conversation history
   - Seamless continuation across sessions

3. **Infrastructure as Code**
   - Modify Bicep templates with AI assistance
   - Deploy with single `azd up` command
   - Version control all infrastructure changes

## Troubleshooting

### MCP Server Issues

1. **Server Not Loading**
   ```bash
   # Check Claude Desktop logs
   tail -f ~/Library/Logs/Claude/claude-desktop.log
   
   # Restart Claude Desktop
   pkill -f "Claude Desktop" && open -a "Claude Desktop"
   ```

2. **Authentication Errors**
   ```bash
   # Verify environment variables
   env | grep AZURE_DEVOPS
   
   # Test Azure DevOps connection
   az boards query --wiql "SELECT [System.Id] FROM WorkItems" \
     --organization "https://dev.azure.com/JT-Ops" \
     --project "JourneyTeam"
   ```

3. **Build Failures**
   ```bash
   # For .NET MCP servers
   cd /path/to/mcp/server
   dotnet clean
   dotnet restore
   dotnet build
   ```

### Azure Deployment Issues

1. **Authentication Problems**
   ```bash
   # Clear and re-authenticate
   azd auth logout
   azd auth login
   
   # Verify subscription
   az account show
   ```

2. **Resource Conflicts**
   ```bash
   # Check resource state
   azd show
   
   # Clean and redeploy
   azd down --force
   azd up
   ```

3. **Bicep Template Errors**
   ```bash
   # Validate template
   az deployment group validate \
     --resource-group rg-name \
     --template-file infra/main.bicep \
     --parameters @infra/main.parameters.json
   ```

### Performance Optimization

1. **MCP Server Response Times**
   - Ensure minimal dependencies in MCP servers
   - Use connection pooling for database/API connections
   - Implement appropriate caching strategies

2. **Claude Desktop Performance**
   - Restart periodically to clear memory
   - Limit number of concurrent MCP servers
   - Monitor system resources

## Best Practices

### Security

1. **Never commit credentials** to source control
2. **Use Key Vault** for production secrets
3. **Rotate PATs regularly** (Azure DevOps tokens)
4. **Apply least privilege** principles to service accounts

### Development

1. **Version control** all infrastructure as code
2. **Use integration tests** with real services (no mocking)
3. **Deploy frequently** with `azd up`
4. **Monitor costs** through Azure Cost Management

### AI Development

1. **Use specific, actionable prompts** with MCP tools
2. **Leverage context persistence** across sessions
3. **Combine multiple MCP servers** for comprehensive assistance
4. **Document custom MCP server capabilities** for team knowledge sharing

## Conclusion

This setup provides a comprehensive AI-assisted development environment that:
- Integrates seamlessly with Azure services
- Provides real-time access to DevOps work items
- Enables infrastructure as code with simple deployment
- Maintains security through proper credential management
- Scales from local development to production deployment

The combination of Claude Desktop with custom and global MCP servers creates a powerful development experience that enhances productivity while maintaining enterprise-grade security and scalability.

---

*Last Updated: June 2025*  
*Author: JourneyTeam Development Team*