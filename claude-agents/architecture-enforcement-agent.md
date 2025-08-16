# Architecture Enforcement Agent

## Purpose
Enforce onion architecture patterns and prevent architectural violations in real-time.

## Violations to Catch

### Domain Layer Violations
```csharp
// ❌ VIOLATION: External dependency in Domain
namespace YourApp.Domain.Models
{
    using Microsoft.EntityFrameworkCore; // BLOCKED!
    using System.ComponentModel.DataAnnotations; // BLOCKED!
}

// ✅ CORRECT: Pure domain model
namespace YourApp.Domain.Models
{
    public class Customer
    {
        public Guid Id { get; private set; }
        public string Name { get; private set; }
        // Pure business logic only
    }
}
```

### Application Layer Violations
```csharp
// ❌ VIOLATION: ViewModel in Application layer
namespace YourApp.Application.Services
{
    public class CustomerViewModel // BLOCKED! Move to Shared/ViewModels
    {
        public string DisplayName { get; set; }
    }
}

// ✅ CORRECT: DTO or Command/Query in Application
namespace YourApp.Application.Commands
{
    public class CreateCustomerCommand
    {
        public string Name { get; set; }
    }
}
```

### Infrastructure Violations
```csharp
// ❌ VIOLATION: Business logic in Infrastructure
namespace YourApp.Infrastructure.Data
{
    public class CustomerRepository
    {
        public void ValidateCustomerAge() // BLOCKED! Move to Domain
        {
            // Business logic doesn't belong here
        }
    }
}

// ✅ CORRECT: Only implementation of interfaces
namespace YourApp.Infrastructure.Data
{
    public class CustomerRepository : ICustomerRepository
    {
        public async Task<Customer> GetByIdAsync(Guid id)
        {
            // Data access only
        }
    }
}
```

## Enforcement Rules

### Directory Structure
```
Solution/
├── src/
│   ├── Domain/           # No external dependencies
│   ├── Application/      # References Domain only
│   ├── Infrastructure/   # References Application & Domain
│   ├── Web/             # References all layers
│   └── Shared/          # ViewModels, DTOs (referenced by all)
```

### Build-Time Enforcement
Add to `.csproj` files:

```xml
<!-- Domain.csproj -->
<ItemGroup>
  <PackageReference Include="Microsoft.EntityFrameworkCore" 
                    Condition="false" /> <!-- Blocked -->
</ItemGroup>

<!-- Application.csproj -->
<ItemGroup>
  <ProjectReference Include="..\Domain\Domain.csproj" />
  <!-- No Infrastructure reference allowed -->
</ItemGroup>
```

## Integration Points

### Git Hooks
```bash
# .git/hooks/pre-commit
#!/bin/bash
claude "As the Architecture Enforcement Agent, validate the onion architecture in staged files"
```

### CI/CD Pipeline
```yaml
- task: DotNetCoreCLI@2
  displayName: 'Architecture Validation'
  inputs:
    command: custom
    custom: 'claude'
    arguments: '"Validate onion architecture compliance"'
```

## Example Prompt
```
claude "As the Architecture Enforcement Agent, review this code change and ensure it follows onion architecture. Block any ViewModels in Application layer and any external dependencies in Domain layer."
```