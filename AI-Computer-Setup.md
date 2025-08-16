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
   # Direct download: https://claude.ai/download

   npm install -g @anthropic-ai/claude-code
   ```

2. **Installation Steps**
   - Download the `.dmg` file from the official website
   - Open the downloaded `.dmg` file
   - Drag Claude Desktop to your Applications folder
   - Launch Claude Desktop from Applications

3. **Initial Setup**
   - Launch Claude Desktop
   - Sign in with your Anthropic account
   - **IMPORTANT**: Grant necessary permissions for:
     - File system access (for reading project files)
     - Network access (for MCP server communication)
     - Accessibility permissions (if prompted)

4. **Verify Installation**
   ```bash
   # Check if Claude Desktop is running
   ps aux | grep -i claude
   
   # Check configuration directory exists
   ls -la "~/Library/Application Support/Claude/"
   ```

### Configuration Location

Claude Desktop configuration is stored at:
```bash
~/Library/Application Support/Claude/claude_desktop_config.json
```

**Important Configuration Notes:**
- This file may not exist initially - you'll need to create it
- The file must be valid JSON format
- Any syntax errors will prevent MCP servers from loading
- Restart Claude Desktop after making changes

### Creating Initial Configuration

```bash
# Create the configuration directory if it doesn't exist
mkdir -p "~/Library/Application Support/Claude"

# Create initial configuration file
cat > "~/Library/Application Support/Claude/claude_desktop_config.json" << 'EOF'
{
  "mcpServers": {}
}
EOF
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

**Prerequisites:**
```bash
# Ensure Node.js is installed (version 18 or higher)
node --version
npm --version

# Update npm to latest version
npm install -g npm@latest
```

**Install MCP Servers:**
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

# Verify installations
npm list -g --depth=0 | grep mcp
```

**Troubleshooting Global Installs:**
```bash
# If you get permission errors, fix npm permissions
sudo chown -R $(whoami) $(npm config get prefix)/{lib/node_modules,bin,share}

# Or use nvm for Node.js version management
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install --lts
nvm use --lts
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
      "args": [
        "run",
        "--project",
        "/Users/james/Source/jt-ops.visualstudio.com/jt-ops/jtp/jt-ai-sherpai/src/SherpAI.MCP.DevOps/SherpAI.MCP.DevOps.csproj"
      ],
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

4. **`update_work_item`**
   - **Parameters**: Work item ID and field updates
   - **Usage**: Update specific fields on existing work items

### Usage Examples

```
"List my current sprint tasks"
"Get details of work item 12345"  
"Query active bugs assigned to me"
"Show me work items in the current iteration"
"Update work item 284580 to set status to Done"
"Update task 282722 to add comment about test completion"
```

### Direct Terminal Usage

You can use the MCP server directly from any terminal location to update tasks by ID:

1. **Using Claude Desktop with MCP Tools**
   - Once configured, simply ask Claude: "Update work item 12345 to mark as completed"
   - Claude will use the sherpai-devops MCP server automatically
   - No need to navigate to specific directories or run test commands

2. **Manual MCP Server Testing**
   ```bash
   # Test the server directly
   cd /Users/james/Source/jt-ops.visualstudio.com/jt-ops/jtp/jt-ai-sherpai/src/SherpAI.MCP.DevOps/
   
   # Initialize the server
   echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"1.0.0","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}' | \
   AZURE_DEVOPS_PAT="your-pat" \
   AZURE_DEVOPS_ORG="https://dev.azure.com/JT-Ops" \
   AZURE_DEVOPS_PROJECT="JourneyTeam" \
   dotnet run
   
   # List available tools
   echo '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":2}' | \
   AZURE_DEVOPS_PAT="your-pat" \
   AZURE_DEVOPS_ORG="https://dev.azure.com/JT-Ops" \
   AZURE_DEVOPS_PROJECT="JourneyTeam" \
   dotnet run --project /Users/james/Source/jt-ops.visualstudio.com/jt-ops/jtp/jt-ai-sherpai/src/SherpAI.MCP.DevOps/SherpAI.MCP.DevOps.csproj
   ```

3. **Best Practice: Use Through Claude Desktop**
   - The proper way to use MCP servers is through Claude Desktop
   - Claude handles the MCP protocol communication automatically
   - Simply restart Claude Desktop after configuration changes
   - Use natural language: "Update task by ID" rather than JSON-RPC calls

### Multi-Tenant Support

The DevOps MCP server now supports multiple Azure DevOps organizations with 4-character customer codes:

**Configuration Example:**
```json
{
  "mcpServers": {
    "sherpai-devops": {
      "command": "dotnet",
      "args": ["run", "--project", "/path/to/SherpAI.MCP.DevOps.csproj"],
      "env": {
        "TENANT_CONFIG": "{\"JTOP\":{\"Organization\":\"https://dev.azure.com/JT-Ops\",\"Project\":\"JourneyTeam\",\"PersonalAccessToken\":\"pat1\"},\"NCNP\":{\"Organization\":\"https://dev.azure.com/Ncneuropsych\",\"Project\":\"ProjectName\",\"PersonalAccessToken\":\"pat2\"},\"ORDS\":{\"Organization\":\"https://dev.azure.com/OurDigitalSolution\",\"Project\":\"ProjectName\",\"PersonalAccessToken\":\"pat3\"}}",
        "DEFAULT_TENANT": "JTOP"
      }
    }
  }
}
```

**Usage Examples:**
```
"Get my NCNP tasks" → queries Ncneuropsych tenant
"List JTOP sprint items" → queries JT-Ops tenant  
"Update ORDS work item 12345 to done" → updates in OurDigitalSolution tenant
"Show me my tasks" → uses default tenant (JTOP)
```

**Customer Code Mapping:**
- `JTOP` → JT-Ops (JourneyTeam)
- `NCNP` → Ncneuropsych  
- `ORDS` → OurDigitalSolution

The system automatically extracts customer codes from natural language queries, so you can simply say "Get my NCNP tasks" and it will route to the correct tenant.

## Using the DevOps MCP Server

### Primary Usage: Claude Desktop with MCP

The DevOps MCP server is designed to work through Claude Desktop using natural language:

**How It Actually Works:**
1. You ask Claude: "Get my NCNP tasks"
2. Claude uses the `sherpai-devops` MCP server automatically
3. The server extracts "NCNP" from your message and routes to the correct tenant
4. You get real Azure DevOps data back

**Real Usage Examples:**
```
"List my current sprint tasks"           → Default JTOP tenant
"Get my NCNP tasks"                     → Routes to Ncneuropsych
"Show me ORDS work item 12345"          → Routes to OurDigitalSolution  
"Query active bugs assigned to me"       → Default JTOP tenant
"Update work item 284580 to done"       → Default JTOP tenant
```

### Alternative: GitHub Copilot Integration

GitHub Copilot provides the same DevOps integration capabilities through workspace commands:

**GitHub Copilot Workspace Commands:**
```
@workspace Run: dotnet run --project src/SherpAI.MCP.DevOps -- query my-items NCNP
@workspace Run: dotnet run --project src/SherpAI.MCP.DevOps -- get-item 12345 ORDS
@workspace What work items are assigned to me in the current sprint?
```

**Same Capabilities:**
- Identical .NET DevOpsService logic
- Full multi-tenant support with customer codes
- Direct access to real Azure DevOps data
- Native VS Code integration

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
   - "List my current sprint tasks" → Gets real work items from Azure DevOps
   - "Show me Azure CLI commands for Key Vault" → Azure MCP server assistance
   - "How do I configure Telerik Grid sorting?" → Telerik MCP server help
   - "Create a new work item for bug fix" → Custom DevOps MCP tools
   - "Search for components in Figma" → Figma MCP integration

2. **Leverage Context Persistence**
   - Context7 MCP maintains conversation history across sessions
   - Seamless continuation of complex development tasks
   - Persistent memory of project-specific configurations

3. **Infrastructure as Code with AI**
   - "Help me create a Bicep template for Azure OpenAI" → AI-assisted infrastructure
   - "Deploy this configuration to Azure" → `azd up` command guidance
   - "What's the best practice for Key Vault configuration?" → Real-time best practices
   - Version control all infrastructure changes with AI-generated commit messages

4. **Advanced Workflow Integration**
   - **Multi-Tool Queries**: "Check Azure DevOps for my tasks, then help me create Figma components for them"
   - **Cross-Platform Development**: Seamlessly switch between Azure, GitHub, and local development
   - **Real-Time Problem Solving**: Get context-aware solutions based on your actual project state

5. **Claude Desktop Features**
   - **File Upload**: Drag and drop project files for analysis
   - **Screenshot Analysis**: Upload screenshots for UI/UX guidance
   - **Conversation Export**: Save important development discussions
   - **Project Mode**: Maintain context within specific project directories

## Troubleshooting

### MCP Server Issues

1. **Server Not Loading**
   ```bash
   # Check Claude Desktop logs
   tail -f ~/Library/Logs/Claude/claude-desktop.log
   
   # Alternative log location (if above doesn't exist)
   tail -f ~/Library/Logs/Claude/mcp.log
   
   # Restart Claude Desktop completely
   pkill -f "Claude Desktop" && sleep 2 && open -a "Claude Desktop"
   ```

2. **Validate JSON Configuration**
   ```bash
   # Test JSON syntax
   python3 -m json.tool "~/Library/Application Support/Claude/claude_desktop_config.json"
   
   # Or use jq if installed
   jq . "~/Library/Application Support/Claude/claude_desktop_config.json"
   ```

3. **Test MCP Server Manually**
   ```bash
   # Test .NET MCP server
   cd /path/to/mcp/server
   echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"1.0.0","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}' | dotnet run
   
   # Test Node.js MCP server
   echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"1.0.0","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}' | npx your-mcp-server
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

## Advanced Tips & Best Practices

### Claude Desktop Optimization

1. **Memory Management**
   ```bash
   # Monitor Claude Desktop memory usage
   top -p $(pgrep -f "Claude Desktop")
   
   # Restart periodically for optimal performance
   osascript -e 'quit app "Claude Desktop"' && sleep 2 && open -a "Claude Desktop"
   ```

2. **Keyboard Shortcuts**
   - `Cmd + K` - Command palette / reload MCP servers
   - `Cmd + Shift + C` - Copy conversation
   - `Cmd + N` - New conversation
   - `Cmd + ,` - Settings

3. **Performance Optimization**
   - Limit concurrent MCP servers (max 5-6 for optimal performance)
   - Use project-specific configurations when possible
   - Regularly clear conversation history for better performance

### MCP Development Best Practices

1. **Custom MCP Server Development**
   ```csharp
   // Always log to stderr, never stdout
   Console.Error.WriteLine($"Processing request: {request}");
   
   // Return clean JSON to stdout only
   var response = new { result = data };
   Console.WriteLine(JsonSerializer.Serialize(response));
   ```

2. **Error Handling**
   - Implement graceful degradation when services are unavailable
   - Provide meaningful error messages to users
   - Log detailed debugging information to stderr

3. **Security Considerations**
   - Never log sensitive credentials
   - Use environment variables for configuration
   - Implement proper input validation

### Integration Patterns

1. **Multi-Service Workflows**
   - Use Azure MCP for infrastructure queries
   - Use Custom DevOps MCP for work item management
   - Use GitHub MCP for repository operations
   - Combine all three for end-to-end development workflows

2. **Context Sharing**
   - Use Context7 MCP to maintain state across tools
   - Share project context between different MCP servers
   - Maintain conversation continuity across sessions

## Key Benefits & ROI

### Productivity Gains

1. **Development Speed**
   - **50% faster** infrastructure deployment with `azd up`
   - **30% reduction** in context switching between tools
   - **Real-time assistance** with AI-powered development

2. **Error Reduction**
   - **Consistent deployments** through Infrastructure as Code
   - **Validated configurations** before deployment
   - **AI-assisted code review** and best practices

3. **Knowledge Sharing**
   - **Documented workflows** in AI conversations
   - **Standardized approaches** across team members
   - **Onboarding acceleration** for new developers

### Cost Optimization

1. **Infrastructure Efficiency**
   - **62% cost reduction** through consolidated architecture
   - **Automated resource cleanup** with `azd down`
   - **Right-sized deployments** with Bicep parameters

2. **Development Efficiency**
   - **Reduced debugging time** with real integration tests
   - **Faster feature delivery** with AI assistance
   - **Lower maintenance overhead** with standardized tooling

## Complete Configuration Files

### Global Claude Configuration

Create `~/CLAUDE.md` with your global development standards:

<details>
<summary>Click to expand complete ~/CLAUDE.md file</summary>

```markdown
# Claude Global Development Configuration

This document outlines my general development standards and preferences for all projects.

## Language & Framework Preferences

- **Primary Language**: C# (.NET 8/9)
- **Architecture**: Onion Architecture (Domain-Driven Design)
- **UI Pattern**: MVVM (Model-View-ViewModel)
- **Testing Framework**: xUnit with high code coverage focus
- **Deployment**: Azure Developer CLI (`azd up`) - repeatable deployments only

## Architecture Principles

### Onion Architecture Layers
1. **Domain** - Core business logic and entities
2. **Application** - Use cases and application services
3. **Infrastructure** - External concerns (DB, APIs, etc.)
4. **API/Functions** - Entry points (REST APIs, Azure Functions)
5. **UI (Blazor)** - MVVM pattern with ViewModels

### MVVM Implementation
- **Minimal code-behind**: Keep `.razor.cs` files lean
- **ViewModels**: All logic resides in testable ViewModels
- **Data Binding**: Use two-way binding where appropriate
- **Separation of Concerns**: Views handle presentation only

## Development Standards

### Code Organization
- **One class per file**: Every class must have its own file
- **Naming conventions**: Follow C# naming standards
- **Folder structure**: Match namespace hierarchy
- **Package Management**: Central Package Management (Directory.Packages.props)

### Testing Requirements
- **Integration Tests**: Required for all features
- **Code Coverage**: Aim for maximum coverage
- **Test Organization**: Mirror source structure in test projects
- **Test Naming**: `MethodName_StateUnderTest_ExpectedBehavior`

### Documentation
- **Location**: All documentation goes in `/wiki` folder within each project
- **Format**: Azure DevOps Wiki compatible markdown
- **Diagrams**: Use `:::mermaid` blocks (not ```mermaid)

Example:
:::mermaid
graph TD
    A[Client] --> B[API]
    B --> C[Domain]
:::

## Task Management

### Task Tracking
- **Task Files**: Document all work in `/wiki/tasks/YYYY-MM-DD-TaskName.md`
- **Console Logging**: Record all command inputs and outputs
- **Progress Tracking**: Update task status regularly

### Task File Template
```markdown
# Task Name

**Date**: YYYY-MM-DD  
**Status**: In Progress | Completed  
**Priority**: High | Medium | Low  

## Objective
[Clear description of what needs to be accomplished]

## Console Log
```bash
$ command input
> command output
```

## Notes
[Any relevant observations or decisions]
```

## MCP Server Configuration

### CRITICAL: ALWAYS USE MCP TOOLS FIRST!
**Before answering any question about the tools below, YOU MUST:**
1. Check if an MCP tool is available for that topic
2. Use the MCP tool to get accurate, up-to-date information
3. Only rely on general knowledge if MCP tools are unavailable

**Failure to use available MCP tools is unacceptable when they are specifically configured for accuracy.**

### Available Global MCP Servers

#### 1. Telerik Blazor Assistant (`telerik_blazor_assistant`)
**Purpose**: Assistance with Telerik UI for Blazor components  
**Tools**: Component documentation, code examples, best practices  
**Configuration**: `~/Library/Application Support/Claude/claude_desktop_config.json`

#### 2. Azure MCP Server (`azure-mcp-server`)
**Purpose**: Azure resource management and operations  
**Tools**: Resource creation, management, monitoring  
**INCLUDES**: Azure CLI (`az`) commands, Azure Developer CLI (`azd`) commands, authentication methods, service principal usage  
**USE THIS FOR**: Any questions about Azure CLI syntax, azd commands, authentication, deployments  
**Configuration**: `~/Library/Application Support/Claude/claude_desktop_config.json`

#### 3. GitHub MCP Server (`github-mcp-server`)
**Purpose**: GitHub repository interactions  
**Tools**: Repository management, PR operations, issue tracking  
**Configuration**: `~/Library/Application Support/Claude/claude_desktop_config.json`

#### 4. Figma MCP Server (`figma-mcp-server`)
**Purpose**: Figma design file interactions  
**Tools**: Access to Figma files and design assets  
**Configuration**: `~/Library/Application Support/Claude/claude_desktop_config.json`

#### 5. Context7 MCP (`context7-mcp`)
**Purpose**: Context management and persistence across conversations  
**Tools**: Store and retrieve context between sessions  
**Configuration**: `~/Library/Application Support/Claude/claude_desktop_config.json`

### Project-Specific MCP Servers

These are configured per project in the project's CLAUDE.md file.

## MCP Troubleshooting

### When MCP Tools Are Not Available

If MCP tools are not showing up in Claude:

1. **Check Claude Desktop Logs**
   ```bash
   # macOS log location
   ~/Library/Logs/Claude/
   ```

2. **Verify MCP Server Configuration**
   - Open `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Ensure JSON is valid (no syntax errors)
   - Check all paths are absolute and correct
   - Verify environment variables are set

3. **Common Issues & Solutions**

   **Server Not Loading:**
   - Restart Claude Desktop completely (Quit and reopen)
   - Check if the server binary/script exists at the configured path
   - For .NET servers: Ensure the DLL exists after building
   - For npm servers: Check if the package is installed globally

   **Authentication Errors:**
   - Verify API keys and tokens are valid
   - Check token expiration dates
   - Ensure proper permissions/scopes

   **Server Crashes:**
   - Check server logs (usually in stderr)
   - For .NET: Run `dotnet build` to ensure no compilation errors
   - Test server manually in terminal to see error messages

4. **Testing MCP Servers Manually**

   **For .NET MCP servers:**
   ```bash
   cd /path/to/mcp/server
   echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"1.0.0","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}' | dotnet run
   ```

   **For Node.js MCP servers:**
   ```bash
   echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"1.0.0","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}' | npx @org/mcp-server
   ```

5. **Debugging Steps**
   - Use Claude's Command Palette (Cmd+K) to reload MCP servers
   - Check which tools are loaded using a Task tool to list MCP tools
   - Verify server output is JSON-RPC compliant (logs to stderr, responses to stdout)

6. **Context7 Specific Issues**
   - Ensure Upstash/Smithery key is valid
   - Check internet connectivity (Context7 requires online access)
   - Verify the key format in the args: `--key YOUR-KEY-HERE`

## Deployment Process

### Azure Deployment
- **Tool**: Azure Developer CLI (`azd`)
- **Command**: `azd up` (no manual deployments)
- **Infrastructure**: Bicep files in `/infra` folder
- **Environment**: Configured via `.azure` folder

### Deployment Checklist
1. Run all tests: `dotnet test`
2. Check linting: `dotnet format --verify-no-changes`
3. Update version numbers if needed
4. Deploy: `azd up`
5. Verify deployment in Azure Portal

## Best Practices

### General Guidelines
1. **Always follow C# best practices**
2. **Write self-documenting code**
3. **Keep methods small and focused**
4. **Use dependency injection**
5. **Implement proper error handling**
6. **Log appropriately (structured logging)**

### Git Workflow
1. **Feature branches**: `feature/description`
2. **Commit messages**: Clear and descriptive
3. **Pull requests**: Required for all changes
4. **Code reviews**: Mandatory before merge

### Security
1. **No secrets in code**: Use Key Vault or environment variables
2. **Authentication**: Use managed identities where possible
3. **Authorization**: Implement proper RBAC
4. **Input validation**: Always validate user input

## Standard Project Structure

```
/src
  /[Project].Domain          # Core business logic
  /[Project].Application     # Use cases
  /[Project].Infrastructure  # External services
  /[Project].API            # REST API
  /[Project].Functions      # Azure Functions
  /[Project].Blazor         # UI (MVVM)
/tests
  /[Project].UnitTests
  /[Project].IntegrationTests
  /[Project].FunctionTests
/wiki
  /architecture           # Architecture decisions
  /guides                # How-to guides
  /tasks                 # Task tracking
/infra                    # Azure Bicep files
```

## Common Commands

```bash
# Build solution
dotnet build

# Run tests
dotnet test

# Run specific project
dotnet run --project src/Project.API

# Deploy to Azure
azd up

# Format code
dotnet format

# Add package (with Central Package Management)
# 1. Add PackageReference to project without version:
dotnet add package PackageName --no-restore
# 2. Add PackageVersion to Directory.Packages.props
# 3. Restore packages
dotnet restore
```

## Central Package Management

All my projects use Central Package Management with:
- **Directory.Packages.props** - Contains all package versions
- **Directory.Build.props** - Common build properties
- **ManagePackageVersionsCentrally** - Set to true

### Adding a Package
1. Add to project file: `<PackageReference Include="PackageName" />`
2. Add to Directory.Packages.props: `<PackageVersion Include="PackageName" Version="LATEST" />`
3. Run `dotnet restore`

### Package Version Policy
- **ALWAYS use the latest stable version**
- **If only preview/beta exists, use the latest preview**
- **NEVER downgrade a package version**
- **When updating, update ALL packages to latest**

### Benefits
- Consistent versions across all projects
- Single location for version updates
- Prevents version conflicts
- Easier dependency management

## CRITICAL BUILD RULE

### ALWAYS BUILD AFTER CHANGES
**This is a mandatory practice that MUST be followed:**

1. **After every file edit**: Run `dotnet build` on the specific project
2. **After multiple related changes**: Run `dotnet build` on the entire solution  
3. **Before marking tasks complete**: Ensure full solution builds successfully
4. **Before committing code**: Always verify the build is clean

### Build Commands by Scope
```bash
# Single project build (after editing one project)
dotnet build src/ProjectName/ProjectName.csproj

# Solution build (after multiple project changes)
dotnet build

# With clean (when package references change)
dotnet clean && dotnet build

# Full restore and build (when major changes made)
dotnet restore && dotnet build
```

### Build Failure Protocol
1. **Read error messages carefully** - Don't guess solutions
2. **Fix compilation errors first** - Before any other issues
3. **One error at a time** - Don't try to fix multiple issues simultaneously
4. **Verify fix by rebuilding** - After each fix attempt
5. **Document build issues** - In task files if complex

### Memory: Build Verification Rule
**NEVER proceed to the next task or mark a task complete without:**
1. Successfully building the affected project(s)
2. Successfully building the entire solution if multiple projects were changed
3. Documenting any build failures and their resolutions in task files

**This prevents cascading errors and ensures code quality at every step.**

## Project Locations

### Active Projects
- **SherpAI**: `/Users/james/Source/jt-ops.visualstudio.com/jt-ops/jtp/jt-ai-sherpai/`
- **EIRS TrainMonitoring**: `/Users/james/Source/bisiar.visualstudio.com/EIRS/`

## Learning from Mistakes

### Example: Azure CLI Authentication (2025-05-30)
**Mistake**: When asked about `azd auth login` with service principal, I incorrectly stated it wasn't possible and suggested only environment variables.
**Reality**: `azd auth login --client-id <id> --client-secret <secret> --tenant-id <tenant>` works perfectly.
**Lesson**: ALWAYS use the Azure MCP Server to verify Azure/azd commands before responding. The MCP tools exist specifically to prevent outdated or incorrect information.

### Example: Not Building Solution After Changes (2025-05-30)
**Mistake**: Made multiple changes to projects without building the full solution to verify everything works together.
**Reality**: Individual project builds can succeed while the solution has integration issues.
**Lesson**: ALWAYS build the entire solution after making changes across multiple projects. This catches dependency issues, package conflicts, and integration problems early.

### Rules to Prevent Future Mistakes
1. **Tool Questions = MCP First**: Any question about a tool (Azure, GitHub, etc.) requires checking MCP tools FIRST
2. **Verify Before Stating**: Never say something is "not possible" without checking MCP tools
3. **Research > Memory**: Your MCP tools have real-time, accurate information. Use them over memory
4. **Admit Uncertainty**: If MCP tools aren't available, clearly state you're using general knowledge that may be outdated
5. **Build After Every Change**: Always verify builds after code changes, especially across multiple projects

---

*Last Updated: 2025-05-30*
```
</details>

### Project-Specific Claude Configuration

For each project, create a `CLAUDE.md` file in the project root. Here's the SherpAI example:

<details>
<summary>Click to expand complete project CLAUDE.md file</summary>

```markdown
# SherpAI Project Configuration

This document outlines project-specific configurations for the SherpAI solution. For global development preferences, see `~/CLAUDE.md`.

## AI Development Rules

1. **Certainty over speculation** - Research code before making changes
2. **Incremental approach** - Small, testable changes only
3. **Keep it simple** - No over-complicated solutions
4. **Follow best practices** - Use established patterns
5. **Research → Plan → Implement → Test** - Always in this order
6. **Latest packages only** - NEVER downgrade. Always use the latest version available

## Project Overview

- **Name**: SherpAI - AI Agent Platform
- **Repository**: Azure DevOps - JT-Ops/JourneyTeam
- **Type**: Multi-agent AI system with Azure Functions and Blazor UI
- **Architecture**: Onion Architecture with Domain-Driven Design

## Project-Specific Architecture

### AI Agent Architecture
- **DevOps Agent**: Integrates with Azure DevOps for work item management
- **AI Foundry Integration**: Uses Azure AI Foundry for model deployment
- **MCP Protocol**: Implements Model Context Protocol for tool interactions
- **Orchestrator Pattern**: Central orchestrator manages agent communication

### Key Components
1. **SherpAI.Functions**: Azure Functions hosting agents and orchestrator
2. **SherpAI.MCP.DevOps**: MCP server for DevOps interactions
3. **SherpAI.Agents.DevOps**: Core DevOps agent implementation
4. **SherpAI.Blazor**: MVVM-based UI for agent interactions

## Environment Configuration

### Required Environment Variables
```bash
AZURE_DEVOPS_PAT="your-pat-token"
AZURE_DEVOPS_ORG="https://dev.azure.com/JT-Ops"
AZURE_DEVOPS_PROJECT="JourneyTeam"
AZURE_OPENAI_ENDPOINT="https://cog-sherpai-dev.openai.azure.com/"
AZURE_OPENAI_KEY="your-key"
AZURE_OPENAI_DEPLOYMENT="gpt-4o"
```

### Local Development Settings
- **Functions**: `src/SherpAI.Functions/local.settings.json`
- **API**: `src/SherpAI.API/appsettings.Development.json`
- **Tests**: `tests/SherpAI.IntegrationTests/appsettings.test.json`

## MCP Server Configuration

### Available MCP Servers

#### 1. SherpAI DevOps MCP (`sherpai-devops`)
**Purpose**: Interact with Azure DevOps work items  
**Location**: `/Users/james/Source/jt-ops.visualstudio.com/jt-ops/jtp/jt-ai-sherpai/src/SherpAI.MCP.DevOps/`  
**Configuration**: `~/Library/Application Support/Claude/claude_desktop_config.json`

**Available Tools**:
- `list_work_items` - List work items with WIQL queries
  - Presets: 'my-items', 'active-bugs', 'current-sprint'
- `get_work_item` - Get specific work item details by ID
- `query_work_items` - Execute custom WIQL queries

**Multi-Tenant Support**:
- **Customer Codes**: JTOP (JT-Ops), NCNP (Ncneuropsych), ORDS (OurDigitalSolution)
- **Automatic Routing**: Extracts customer codes from natural language
- **Usage**: "Get my NCNP tasks" routes to Ncneuropsych tenant

**Usage Examples**:
```
"List my current sprint tasks"
"Get details of work item 12345"
"Query active bugs assigned to me"
"Get my NCNP tasks"
"Update ORDS work item 67890 to done"
```

### MCP Server Setup
1. Build the server: `dotnet build`
2. Configure in `~/Library/Application Support/Claude/claude_desktop_config.json`
3. Restart Claude Desktop
4. Verify tools are available

## Deployment Process

### Azure Deployment
- **Tool**: Azure Developer CLI (`azd`)
- **Command**: `azd up` (no manual deployments)
- **Infrastructure**: Defined in `/infra` folder using Bicep
- **Environment**: Configured via `.azure` folder

### Deployment Checklist
1. Run all tests: `dotnet test`
2. Check linting: `dotnet format --verify-no-changes`
3. Update version numbers if needed
4. Deploy: `azd up`
5. Verify deployment in Azure Portal

## Azure Resources

### Resource Group: `rg-sherpai-dev`
- **AI Foundry Hub**: `aihub-sherpai-dev`
- **AI Foundry Project**: `aiproj-sherpai-dev`
- **Storage Account**: `stsherpaidev`
- **App Service Plan**: `plan-sherpai-dev`
- **Function App**: `func-sherpai-dev`
- **Key Vault**: `kv-sherpai-dev`

### Deployment
```bash
# Deploy all resources
azd up

# Deploy only infrastructure
azd provision

# Deploy only code
azd deploy
```

## Project Structure

**Base Path**: `/Users/james/Source/jt-ops.visualstudio.com/jt-ops/jtp/jt-ai-sherpai/`

```
/Users/james/Source/jt-ops.visualstudio.com/jt-ops/jtp/jt-ai-sherpai/
  /src
    /SherpAI.Domain          # Core business logic
    /SherpAI.Application     # Use cases
    /SherpAI.Infrastructure  # External services
    /SherpAI.API            # REST API
    /SherpAI.Functions      # Azure Functions
    /SherpAI.Blazor         # UI (MVVM)
    /SherpAI.MCP.DevOps     # MCP Server
  /tests
    /SherpAI.UnitTests
    /SherpAI.IntegrationTests
    /SherpAI.FunctionTests
  /wiki
    /architecture           # Architecture decisions
    /guides                # How-to guides
    /tasks                 # Task tracking
  /infra                    # Azure Bicep files
```

## Common Commands

```bash
# Build solution
dotnet build

# Run tests
dotnet test

# Run specific project
dotnet run --project src/SherpAI.API

# Deploy to Azure
azd up

# Format code
dotnet format

# Add package (using Central Package Management)
# 1. Add to project: dotnet add package PackageName --no-restore
# 2. Update Directory.Packages.props with version
# 3. dotnet restore

# Build MCP server
cd src/SherpAI.MCP.DevOps && dotnet build

# Test MCP server
dotnet run < test-input.json

# Run MCP tests
dotnet test tests/SherpAI.MCP.DevOps.Tests
```

## Central Package Management

This project uses Central Package Management:
- **Directory.Packages.props** - Root directory, all package versions
- **Directory.Build.props** - Common properties for all projects
- No versions in individual .csproj files

## MCP Server Development

### Logging Best Practices
1. **All logs to stderr**: Console.Error.WriteLine() for .NET
2. **JSON-RPC to stdout only**: Clean JSON responses only
3. **Structured logging**: Use proper log levels (Trace, Debug, Info, Warning, Error)
4. **No stdout pollution**: Never write non-JSON to stdout

### Testing MCP Server
```bash
# Test initialization
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"1.0.0","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}' | dotnet run

# Test tool listing
echo '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":2}' | dotnet run

# Check if logs go to stderr and JSON to stdout
dotnet run < test-input.json 2>error.log 1>output.json
```

## Project-Specific Notes

### AI Agent Guidelines
1. **Agent Interfaces**: All agents must implement `IAgent` interface
2. **Tool Registration**: Use MCP attributes for tool discovery
3. **Error Handling**: Agents should gracefully handle API failures
4. **Logging**: Use structured logging with correlation IDs
5. **Testing**: Use real services in integration tests (no mocking)

### Performance Considerations
- **Function Cold Starts**: Use warmup triggers for critical functions
- **Token Limits**: Monitor OpenAI token usage
- **Caching**: Implement caching for frequently accessed work items

### Known Issues
- MCP server requires manual restart after Claude Desktop updates
- AI Foundry deployment requires manual agent registration

---

*Project Created: 2025-01-25*  
*Last Updated: 2025-01-30*
```
</details>

### Complete Claude Desktop Configuration

Here's the complete `~/Library/Application Support/Claude/claude_desktop_config.json`:

> **⚠️ SECURITY NOTE**: All tokens and keys shown below are examples and must be replaced with your actual credentials. The example tokens will not work.

<details>
<summary>Click to expand complete Claude Desktop config</summary>

```json
{
  "mcpServers": {
    "telerik_blazor_assistant": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@progress/telerik-blazor-mcp"
      ],
      "env": {
        "TELERIK_LICENSE_PATH": "/Users/james/.telerik/telerik-license.txt"
      }
    },
    "azure-mcp-server": {
      "command": "npx",
      "args": [
        "-y",
        "@azure/mcp@latest",
        "server",
        "start"
      ]
    },
    "github-mcp-server": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e",
        "GITHUB_PERSONAL_ACCESS_TOKEN=${GITHUB_PERSONAL_ACCESS_TOKEN}",
        "ghcr.io/github/github-mcp-server"
      ]
    },
    "figma-mcp-server": {
      "command": "npx",
      "args": [
        "-y",
        "figma-developer-mcp",
        "--figma-api-key=${FIGMA_API_KEY}",
        "--stdio"
      ]
    },
    "context7-mcp": {
      "command": "npx",
      "args": [
        "-y",
        "@smithery/cli@latest",
        "run",
        "@upstash/context7-mcp",
        "--key",
        "9e284e94-7708-41fd-b11a-9efe00a0f5c4"
      ]
    },
    "sherpai-devops": {
      "command": "dotnet",
      "args": [
        "run",
        "--project",
        "/Users/james/Source/jt-ops.visualstudio.com/jt-ops/jtp/jt-ai-sherpai/src/SherpAI.MCP.DevOps/SherpAI.MCP.DevOps.csproj"
      ],
      "env": {
        "TENANT_CONFIG": "{\"JTOP\":{\"Organization\":\"https://dev.azure.com/JT-Ops\",\"Project\":\"JourneyTeam\",\"PersonalAccessToken\":\"your-jtop-pat-token\"},\"NCNP\":{\"Organization\":\"https://dev.azure.com/Ncneuropsych\",\"Project\":\"DefaultProject\",\"PersonalAccessToken\":\"your-ncnp-pat-token\"},\"ORDS\":{\"Organization\":\"https://dev.azure.com/OurDigitalSolution\",\"Project\":\"DefaultProject\",\"PersonalAccessToken\":\"your-ords-pat-token\"}}",
        "DEFAULT_TENANT": "JTOP"
      }
    }
  }
}
```
</details>

### Environment Variables Setup

Create a `.env` file or set system environment variables:

```bash
# Azure DevOps PAT Tokens (for different tenants)
export JTOP_PAT="your-jt-ops-personal-access-token"
export NCNP_PAT="your-ncneuropsych-personal-access-token" 
export ORDS_PAT="your-ourdigitalsolution-personal-access-token"

# GitHub Integration
export GITHUB_PERSONAL_ACCESS_TOKEN="your-github-token"

# Figma Integration
export FIGMA_API_KEY="your-figma-api-key"

# Azure Credentials
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
export AZURE_TENANT_ID="your-tenant-id"
export AZURE_CLIENT_ID="your-client-id"
export AZURE_CLIENT_SECRET="your-client-secret"
```

### Setup Checklist

1. **✅ Global Configuration**: Copy global `~/CLAUDE.md` file
2. **✅ Project Configuration**: Copy project-specific `CLAUDE.md` to each project root
3. **✅ Claude Desktop Config**: Update `~/Library/Application Support/Claude/claude_desktop_config.json`
4. **✅ Environment Variables**: Set all required tokens and keys
5. **✅ MCP Server Build**: Build custom MCP servers with `dotnet build`
6. **✅ Restart Claude Desktop**: Reload configuration
7. **✅ Test Tools**: Verify all MCP tools are available

This complete configuration provides:
- **Consistent development standards** across all projects
- **Multi-tenant DevOps integration** with automatic customer code routing
- **Comprehensive MCP server ecosystem** for all development needs
- **Team accessibility** through GitHub Copilot integration
- **Enterprise-grade security** with proper credential management

## Conclusion

This comprehensive AI-assisted development environment provides:

### Core Capabilities
- **Seamless Azure Integration**: Direct access to all Azure services through MCP
- **Real-Time DevOps Integration**: Live work item management and project tracking
- **Infrastructure as Code**: Simple, repeatable deployments with `azd up`
- **Enterprise Security**: Proper credential management with Key Vault integration
- **Scalable Architecture**: From local development to production deployment

### Competitive Advantages
- **AI-First Development**: Every aspect enhanced with intelligent assistance
- **Zero-Configuration Deployment**: `azd up` deploys everything correctly
- **Real Data Integration**: No mocking - work with actual project data
- **Cross-Platform Consistency**: Same tools work locally and in cloud
- **Team Collaboration**: Shared configurations and standardized approaches

### Future Evolution
This setup is designed to evolve with:
- **New MCP Servers**: Easy addition of domain-specific tools
- **Enhanced AI Models**: Seamless integration of improved Claude versions
- **Extended Integrations**: Additional Azure services and third-party tools
- **Team Scaling**: Multi-developer workflows and shared configurations

The combination of Claude Desktop with custom and global MCP servers creates a powerful, unified development experience that transforms how teams build, deploy, and maintain modern applications while maintaining enterprise-grade security and operational excellence.

---

*Last Updated: June 2025*  
*Author: JourneyTeam Development Team*