# Getting Started with Claude Code Subagents

## How Agents Work

**Important**: Claude Code Subagents are **not background services or daemons**. They are:
- **On-demand tools** triggered by specific events
- **Git hook activated** for automatic validation
- **Manually invokable** via command line
- **VS Code integrated** through tasks

## Installation (5 minutes)

### Prerequisites
1. Claude Code installed (`claude --version`)
2. Git repository initialized
3. Azure project with `/infra` folder (optional)

### Quick Setup

```bash
# 1. Clone or copy the agent files to your project
cp -r /path/to/claude-agents .

# 2. Run the setup script
chmod +x claude-agents/setup.sh
./claude-agents/setup.sh

# 3. Load agent aliases
source .claude/agents/aliases.sh

# 4. Declare your specialization
echo "Specialization: AI Platform on Microsoft Azure" >> README.md
```

## Agent Invocation Methods

### Method 1: Git Hooks (Automatic)

Agents run automatically on git operations:

```bash
# Pre-commit: Architecture & naming validation
git add .
git commit -m "Add new feature"
# 🏛️ Validating Onion Architecture... [automatic]
# ☁️ Validating Azure naming conventions... [automatic]

# Post-commit: Documentation updates  
# 📚 Updating WAF documentation... [automatic in background]
```

### Method 2: Command Aliases (Manual)

After sourcing aliases, use short commands:

```bash
# Source the aliases (add to ~/.bashrc or ~/.zshrc for persistence)
source .claude/agents/aliases.sh

# Use agent commands
claude-docs      # Update all documentation
claude-arch      # Validate architecture
claude-azure     # Check Azure naming
claude-audit     # Check audit readiness
claude-validate  # Run all validations
```

### Method 3: Direct Claude Commands

Call agents directly with full prompts:

```bash
# Documentation Agent
claude "As the WAF Documentation Agent, analyze the current codebase and update documentation"

# Architecture Agent
claude "As the Architecture Enforcement Agent, validate onion architecture"

# Azure Agent
claude "As the Azure Infrastructure Agent, generate Bicep templates for project 'my-app'"

# Audit Agent
claude "As the Audit Orchestration Agent, check readiness for AI Platform specialization"
```

### Method 4: VS Code Tasks

1. Open VS Code
2. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
3. Type "Tasks: Run Task"
4. Select:
   - `Claude: Validate Architecture`
   - `Claude: Update Documentation`
   - `Claude: Check Audit Readiness`
   - `Claude: Generate Azure Infrastructure`

### Method 5: Scripted Automation

Run all agents at once:

```bash
# Full validation and documentation
.claude/run-all-agents.sh

# Quick audit check
.claude/quick-audit.sh
```

## File Watching (Optional - Linux/WSL Only)

For continuous monitoring, set up the systemd service:

```bash
# 1. Edit the service file with your project path
sed -i "s|YOUR_PROJECT|$(basename $PWD)|g" .claude/agents/claude-watcher.service

# 2. Install the service
cp .claude/agents/claude-watcher.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable claude-watcher
systemctl --user start claude-watcher

# 3. Check status
systemctl --user status claude-watcher

# 4. View logs
journalctl --user -u claude-watcher -f
```

## Project Structure After Setup

```
your-project/
├── .claude/
│   ├── agents/
│   │   ├── aliases.sh           # Command shortcuts
│   │   ├── watch.sh            # File watcher script
│   │   └── *.md                # Agent documentation
│   ├── config.yaml             # Agent configuration
│   ├── run-all-agents.sh      # Run all validations
│   └── quick-audit.sh         # Audit readiness check
├── .git/hooks/
│   ├── pre-commit              # Architecture validation
│   └── post-commit             # Documentation updates
├── .vscode/
│   └── tasks.json              # VS Code integration
├── infra/
│   ├── main.bicep              # Azure infrastructure
│   └── abbreviations.json      # Naming conventions
├── docs/
│   └── audit/                  # Audit evidence
├── src/
│   ├── Domain/                 # Pure business logic
│   ├── Application/            # Use cases
│   ├── Infrastructure/         # External concerns
│   ├── Web/                    # Presentation
│   └── Shared/                 # ViewModels, DTOs
└── README.md                    # With specialization declaration
```

## Configuration

### Update Specialization

Edit `README.md`:
```markdown
## Specialization
AI Platform on Microsoft Azure
```

Available specializations:
- AI Platform on Microsoft Azure
- Web Applications Modernization  
- Azure Virtual Desktop
- Data Platform on Microsoft Azure
- Infrastructure on Microsoft Azure

### Customize Agent Behavior

Edit `.claude/config.yaml`:
```yaml
# Enable/disable specific agents
triggers:
  documentation:
    enabled: true
    on_commit: true
  architecture:
    enabled: true
    block_violations: true  # Block commits with violations
  azure:
    enabled: true
    validate_naming: true
  audit:
    enabled: true
    weekly_check: false    # Manual only

# Document limits
documentation:
  max_files: 10          # Keep documentation lean
  max_pages_per_file: 4  # Concise documents
```

## Common Workflows

### Starting a New Project

```bash
# 1. Initialize
mkdir my-project && cd my-project
git init

# 2. Setup agents
./claude-agents/setup.sh

# 3. Generate initial structure
claude "As the Azure Infrastructure Agent, create initial Bicep templates for 'my-project'"
claude "As the WAF Documentation Agent, create initial documentation structure"

# 4. Commit with validation
git add .
git commit -m "Initial project setup"  # Agents validate automatically
```

### Daily Development

```bash
# Morning: Check status
claude-validate           # Run all validations
.claude/quick-audit.sh   # Check audit readiness

# During development: Automatic validation
git commit               # Hooks validate architecture

# End of day: Update docs
claude-docs              # Regenerate documentation
```

### Pre-Audit Preparation

```bash
# 1. Full audit check
claude-audit

# 2. Generate missing evidence
claude "As the Audit Orchestration Agent, generate all missing evidence for Module B"

# 3. Export audit package
claude "Create audit package with all evidence for Microsoft reviewer"
```

## Troubleshooting

### Agents Not Running on Commit

```bash
# Check hook permissions
ls -la .git/hooks/
chmod +x .git/hooks/*

# Test hooks manually
.git/hooks/pre-commit
```

### Documentation Not Updating

```bash
# Force regeneration
claude-docs

# Check for errors
claude "As the WAF Documentation Agent, diagnose why documentation isn't updating"
```

### Architecture Violations Not Caught

```bash
# Verify configuration
cat .claude/config.yaml

# Test validation manually
claude-arch

# Get detailed report
claude "As the Architecture Enforcement Agent, provide detailed violation report"
```

### VS Code Tasks Not Working

```bash
# Verify Claude is in PATH
which claude

# Check task configuration
cat .vscode/tasks.json

# Run task command manually
claude "As the Architecture Enforcement Agent, validate the onion architecture"
```

## Best Practices

### 1. Commit Often
- Agents validate on every commit
- Catches issues early
- Keeps documentation current

### 2. Use Aliases
```bash
# Add to ~/.bashrc or ~/.zshrc
echo "source ~/projects/my-app/.claude/agents/aliases.sh" >> ~/.bashrc
```

### 3. Regular Audits
```bash
# Weekly audit check (add to crontab)
0 9 * * 1 cd /path/to/project && .claude/quick-audit.sh
```

### 4. Team Onboarding
```bash
# New team member setup
git clone <repo>
cd <repo>
./claude-agents/setup.sh
source .claude/agents/aliases.sh
claude-validate  # Verify everything works
```

## Integration with CI/CD

### Azure DevOps Pipeline

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

steps:
- script: |
    # Install Claude (if not in image)
    # ... installation steps ...
    
    # Run validations
    claude "As the Architecture Enforcement Agent, validate all code"
    claude "As the Azure Infrastructure Agent, validate all naming"
  displayName: 'Claude Agent Validation'

- script: |
    # Generate audit evidence
    claude "As the Audit Orchestration Agent, generate build evidence"
  displayName: 'Generate Audit Evidence'
```

### GitHub Actions

```yaml
name: Claude Agents Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Run Architecture Validation
      run: |
        claude "As the Architecture Enforcement Agent, validate onion architecture"
    
    - name: Run Azure Naming Validation  
      run: |
        claude "As the Azure Infrastructure Agent, validate resource naming"
    
    - name: Update Documentation
      if: github.ref == 'refs/heads/main'
      run: |
        claude "As the WAF Documentation Agent, update all documentation"
        git config user.name "Claude Agent"
        git config user.email "claude@example.com"
        git add -A
        git diff --staged --quiet || git commit -m "Update documentation [skip ci]"
        git push
```

## Support

- **Issues**: Create in your project repository
- **Specializations**: https://github.com/Bisiar/JourneyTeam-Azure
- **Updates**: Check claude-agents/README.md for latest version

---

*Remember: Agents are tools that run on-demand, not services. They help enforce standards and maintain documentation but don't run continuously in the background.*