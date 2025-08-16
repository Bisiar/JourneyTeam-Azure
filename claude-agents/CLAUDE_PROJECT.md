# Claude Code Agent Instructions

## IMPORTANT: Active Subagents

This project has the following Claude Code subagents that MUST be considered:

### 1. Azure Infrastructure Agent
- **ALWAYS** use project name (e.g., 'reflections') not resourceToken for naming
- Resource naming patterns:
  - Resource Groups: `rg-{projectname}-{environment}`
  - Function Apps: `func-{projectname}-{environment}`
  - Storage Accounts: `st{projectname}{environment}` (no hyphens, lowercase)
  - Key Vaults: `kv-{projectname}-{environment}`
  - SQL Servers: `sql-{projectname}-{environment}`
  - App Service Plans: `plan-{projectname}-{environment}`

### 2. Architecture Enforcement Agent
- **ENFORCE** Onion Architecture:
  - Domain layer: NO external dependencies (no EntityFramework, no Azure SDK)
  - Application layer: NO ViewModels (put in Shared/ViewModels)
  - Infrastructure layer: Implements Application interfaces
  - Web/UI layer: Uses ViewModels from Shared

### 3. WAF Documentation Agent
- Maintain these 10 documents maximum:
  - ARCHITECTURE.md, OPERATIONS.md, SECURITY.md
  - PERFORMANCE.md, COST.md, TESTING.md
  - DEPLOYMENT.md, AUDIT_EVIDENCE.md
  - README.md, RUNBOOK.md

### 4. Audit Orchestration Agent
- Check specialization from README.md
- Validate against Azure Advanced Specialization requirements
- Generate audit evidence with proper naming

## CRITICAL RULES FOR CLAUDE

### When Creating Infrastructure (Bicep/Terraform):
```bicep
// ❌ WRONG - Using resourceToken
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
name: '${abbrs.webSitesFunctions}${resourceToken}'

// ✅ CORRECT - Using project name
var projectName = 'reflections'  // Or from parameter
name: '${abbrs.webSitesFunctions}${projectName}-${environment}'
```

### When Creating Code:
```csharp
// ❌ WRONG - ViewModel in Application layer
namespace MyApp.Application.ViewModels
{
    public class CustomerViewModel { }
}

// ✅ CORRECT - ViewModel in Shared
namespace MyApp.Shared.ViewModels
{
    public class CustomerViewModel { }
}
```

### When Generating Names:
```bash
# ❌ WRONG
rg-6b2s6nhalemmo
func-6b2s6nhalemmo
st6b2s6nhalemmo

# ✅ CORRECT
rg-reflections-prod
func-reflections-prod
streflectionsprod
```

## Agent Integration Status

The agents are configured to:
1. Monitor file changes in real-time
2. Validate architecture on commits
3. Check Azure naming conventions
4. Update documentation automatically

## Before Responding, Always Check:

1. **For Infrastructure tasks**: Am I using the project name instead of resourceToken?
2. **For Code tasks**: Am I following Onion Architecture?
3. **For Documentation tasks**: Am I updating the right WAF-aligned documents?
4. **For Naming tasks**: Am I following Microsoft's abbreviations?

## Example Correct Responses:

### Infrastructure Request:
"I'll create the Bicep template using 'reflections' as the project name for all resources, following the pattern rg-reflections-{environment}"

### Architecture Request:
"I'll place the ViewModel in the Shared/ViewModels folder to maintain proper Onion Architecture separation"

### Naming Request:
"The storage account will be named 'streflectionsprod' (lowercase, no hyphens, max 24 chars)"

---

**Remember**: The agents are watching! They will validate your output and flag violations.