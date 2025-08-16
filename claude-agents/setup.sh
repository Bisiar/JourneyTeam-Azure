#!/bin/bash

# Claude Code Subagents Setup Script
# Sets up git hooks, aliases, and configurations for WAF-aligned development

set -e

echo "🚀 Setting up Claude Code Subagents for Azure WAF & Audit Readiness"
echo "=================================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    echo "Please run this script from your project root"
    exit 1
fi

# Check if Claude is installed
if ! command -v claude &> /dev/null; then
    echo -e "${RED}❌ Error: Claude Code is not installed${NC}"
    echo "Install from: https://claude.ai/download"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites checked${NC}"

# Create agent directories
echo -e "\n${YELLOW}📁 Creating directory structure...${NC}"
mkdir -p .claude/agents
mkdir -p .claude/templates
mkdir -p .claude/hooks
mkdir -p docs/audit
mkdir -p infra

# Copy agent configurations
echo -e "${YELLOW}📝 Installing agent configurations...${NC}"
if [ -d "claude-agents" ]; then
    cp -r claude-agents/* .claude/agents/
    echo -e "${GREEN}✅ Agent configurations installed${NC}"
else
    echo -e "${YELLOW}⚠️  Agent configurations not found, creating defaults...${NC}"
fi

# Set up Git hooks
echo -e "\n${YELLOW}🔗 Setting up Git hooks...${NC}"

# Pre-commit hook for architecture validation
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Claude Architecture Enforcement Hook

echo "🏛️  Validating Onion Architecture..."

# Check for ViewModels in wrong places
if git diff --cached --name-only | grep -E "Application.*ViewModel\.cs$"; then
    echo "❌ ERROR: ViewModels detected in Application layer!"
    echo "Move ViewModels to Shared/ViewModels or Contracts/"
    exit 1
fi

# Check for database references in Domain
if git diff --cached --name-only | xargs grep -l "Microsoft.EntityFrameworkCore" | grep -E "Domain/"; then
    echo "❌ ERROR: Entity Framework reference detected in Domain layer!"
    echo "Domain layer must have no external dependencies"
    exit 1
fi

# Validate Azure naming if infrastructure files changed
if git diff --cached --name-only | grep -E "infra/.*\.bicep$"; then
    echo "☁️  Validating Azure naming conventions..."
    claude "As the Azure Infrastructure Agent, validate the naming conventions in staged Bicep files" --no-interactive
    if [ $? -ne 0 ]; then
        echo "❌ Azure naming validation failed"
        exit 1
    fi
fi

echo "✅ Architecture validation passed"
EOF

chmod +x .git/hooks/pre-commit

# Post-commit hook for documentation updates
cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash
# Claude Documentation Update Hook

echo "📚 Updating WAF documentation..."

# Only update if source files changed
if git diff-tree --no-commit-id --name-only -r HEAD | grep -E "\.(cs|ts|js|bicep)$"; then
    claude "As the WAF Documentation Agent, update documentation based on the latest changes" --no-interactive &
    echo "📝 Documentation update triggered in background"
fi
EOF

chmod +x .git/hooks/post-commit

echo -e "${GREEN}✅ Git hooks installed${NC}"

# Create agent aliases for easy invocation
echo -e "\n${YELLOW}🔧 Creating agent aliases...${NC}"

cat > .claude/agents/aliases.sh << 'EOF'
#!/bin/bash
# Claude Agent Aliases - Source this file or add to your shell profile

# Documentation Agent
alias claude-docs='claude "As the WAF Documentation Agent, analyze the current codebase and update documentation to align with the Azure specialization in README.md. Keep to 10 documents maximum."'

# Architecture Enforcement Agent  
alias claude-arch='claude "As the Architecture Enforcement Agent, validate the onion architecture in all source files and report any violations with suggested fixes."'

# Azure Infrastructure Agent
alias claude-azure='claude "As the Azure Infrastructure Agent, validate all resource naming in the /infra folder and ensure compliance with Microsoft naming standards."'

# Audit Orchestration Agent
alias claude-audit='claude "As the Audit Orchestration Agent, check our audit readiness for the specialization defined in README.md and generate a compliance report."'

# Quick validation of everything
alias claude-validate='claude-arch && claude-azure && echo "✅ All validations passed"'

# Generate all documentation
alias claude-generate-docs='claude "Generate all 10 core WAF documents: ARCHITECTURE.md, OPERATIONS.md, SECURITY.md, PERFORMANCE.md, COST.md, TESTING.md, DEPLOYMENT.md, AUDIT_EVIDENCE.md, README.md, and RUNBOOK.md"'
EOF

chmod +x .claude/agents/aliases.sh

# Create systemd service (optional - for Linux/WSL users who want continuous monitoring)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo -e "\n${YELLOW}🔄 Creating systemd service for file monitoring (optional)...${NC}"
    
    cat > .claude/agents/claude-watcher.service << 'EOF'
[Unit]
Description=Claude Code Agent File Watcher
After=network.target

[Service]
Type=simple
WorkingDirectory=%h/Source/YOUR_PROJECT
ExecStart=/usr/bin/bash %h/Source/YOUR_PROJECT/.claude/agents/watch.sh
Restart=always
User=%u

[Install]
WantedBy=default.target
EOF

    cat > .claude/agents/watch.sh << 'EOF'
#!/bin/bash
# File watcher for triggering Claude agents on changes

WATCH_DIRS="src Domain Application Infrastructure Web"

inotifywait -m -r -e modify,create,delete $WATCH_DIRS |
while read path action file; do
    case "$file" in
        *.cs|*.ts|*.js)
            echo "Code change detected: $file"
            claude "As the Architecture Enforcement Agent, validate the changes in $file" --no-interactive
            ;;
        *.bicep|*.json)
            echo "Infrastructure change detected: $file"
            claude "As the Azure Infrastructure Agent, validate naming in $file" --no-interactive
            ;;
    esac
done
EOF

    chmod +x .claude/agents/watch.sh
    echo -e "${YELLOW}ℹ️  To enable continuous monitoring (Linux/WSL only):${NC}"
    echo "  1. Update paths in .claude/agents/claude-watcher.service"
    echo "  2. cp .claude/agents/claude-watcher.service ~/.config/systemd/user/"
    echo "  3. systemctl --user enable claude-watcher"
    echo "  4. systemctl --user start claude-watcher"
fi

# Create VS Code tasks
echo -e "\n${YELLOW}📝 Creating VS Code tasks...${NC}"
mkdir -p .vscode

cat > .vscode/tasks.json << 'EOF'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Claude: Validate Architecture",
            "type": "shell",
            "command": "claude",
            "args": ["As the Architecture Enforcement Agent, validate the onion architecture"],
            "group": "test",
            "presentation": {
                "reveal": "always",
                "panel": "new"
            }
        },
        {
            "label": "Claude: Update Documentation",
            "type": "shell",
            "command": "claude",
            "args": ["As the WAF Documentation Agent, update all documentation"],
            "group": "build",
            "presentation": {
                "reveal": "always",
                "panel": "new"
            }
        },
        {
            "label": "Claude: Check Audit Readiness",
            "type": "shell",
            "command": "claude",
            "args": ["As the Audit Orchestration Agent, check audit readiness"],
            "group": "test",
            "presentation": {
                "reveal": "always",
                "panel": "new"
            }
        },
        {
            "label": "Claude: Generate Azure Infrastructure",
            "type": "shell",
            "command": "claude",
            "args": ["As the Azure Infrastructure Agent, generate Bicep templates with proper naming"],
            "group": "build",
            "presentation": {
                "reveal": "always",
                "panel": "new"
            }
        }
    ]
}
EOF

echo -e "${GREEN}✅ VS Code tasks created${NC}"

# Create initial configuration
echo -e "\n${YELLOW}⚙️  Creating initial configuration...${NC}"

cat > .claude/config.yaml << 'EOF'
# Claude Subagent Configuration
project_name: ${PROJECT_NAME:-my-project}
environment: ${ENVIRONMENT:-dev}
azure_region: ${AZURE_REGION:-eastus}

# Specialization (update based on your project)
specialization: "AI Platform on Microsoft Azure"
specialization_source: "https://github.com/Bisiar/JourneyTeam-Azure/tree/main/specializations"

# Agent triggers
triggers:
  documentation:
    enabled: true
    on_commit: true
    on_push: false
  architecture:
    enabled: true
    on_commit: true
    block_violations: true
  azure:
    enabled: true
    validate_naming: true
  audit:
    enabled: true
    weekly_check: true

# Document limits
documentation:
  max_files: 10
  max_pages_per_file: 4
  format: markdown

# Azure naming patterns
azure:
  abbreviations_url: "https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations"
  enforce_globally_unique:
    - storage_account
    - key_vault
    - sql_server
EOF

# Create sample specialization declaration
if [ ! -f README.md ]; then
    echo -e "\n${YELLOW}📄 Creating README with specialization declaration...${NC}"
    cat > README.md << 'EOF'
# Project Name

## Specialization
AI Platform on Microsoft Azure

## Quick Start
```bash
# Deploy to Azure
azd up

# Run locally
dotnet run
```

## Documentation
- [Architecture](./ARCHITECTURE.md)
- [Operations](./OPERATIONS.md)
- [Security](./SECURITY.md)
- [Performance](./PERFORMANCE.md)
- [Cost](./COST.md)
- [Testing](./TESTING.md)
- [Deployment](./DEPLOYMENT.md)
- [Audit Evidence](./AUDIT_EVIDENCE.md)
- [Runbook](./RUNBOOK.md)
EOF
    echo -e "${GREEN}✅ README created with specialization${NC}"
fi

# Create helper scripts
echo -e "\n${YELLOW}🛠️  Creating helper scripts...${NC}"

cat > .claude/run-all-agents.sh << 'EOF'
#!/bin/bash
# Run all Claude agents for complete validation

echo "🤖 Running all Claude Code Subagents..."
echo "======================================"

# 1. Architecture check
echo -e "\n🏛️  Architecture Enforcement Agent"
claude "As the Architecture Enforcement Agent, validate the entire codebase for onion architecture compliance" --no-interactive

# 2. Azure naming check
echo -e "\n☁️  Azure Infrastructure Agent"
claude "As the Azure Infrastructure Agent, validate all resource naming conventions" --no-interactive

# 3. Documentation update
echo -e "\n📚 WAF Documentation Agent"
claude "As the WAF Documentation Agent, update all documentation to current state" --no-interactive

# 4. Audit readiness
echo -e "\n✅ Audit Orchestration Agent"
claude "As the Audit Orchestration Agent, generate audit readiness report" --no-interactive

echo -e "\n✨ All agents completed!"
EOF

chmod +x .claude/run-all-agents.sh

cat > .claude/quick-audit.sh << 'EOF'
#!/bin/bash
# Quick audit readiness check

echo "🔍 Quick Audit Readiness Check"
echo "=============================="

# Check for required documents
REQUIRED_DOCS=("ARCHITECTURE.md" "OPERATIONS.md" "SECURITY.md" "PERFORMANCE.md" "COST.md" "TESTING.md" "DEPLOYMENT.md" "AUDIT_EVIDENCE.md" "README.md" "RUNBOOK.md")

echo -e "\n📄 Document Checklist:"
for doc in "${REQUIRED_DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo "  ✅ $doc"
    else
        echo "  ❌ $doc (missing)"
    fi
done

# Check specialization
echo -e "\n🎯 Specialization:"
if grep -q "Specialization:" README.md; then
    grep "Specialization:" README.md
else
    echo "  ⚠️  No specialization declared in README.md"
fi

# Check infrastructure
echo -e "\n🏗️  Infrastructure:"
if [ -d "infra" ] && [ -f "infra/main.bicep" ]; then
    echo "  ✅ Bicep templates found"
else
    echo "  ❌ Missing infra/main.bicep"
fi

# Run audit agent for detailed report
echo -e "\n📊 Detailed Audit Report:"
claude "As the Audit Orchestration Agent, provide a quick audit readiness summary" --no-interactive
EOF

chmod +x .claude/quick-audit.sh

# Final setup summary
echo -e "\n${GREEN}✨ Setup Complete!${NC}"
echo "=================="
echo ""
echo "📁 Created directories:"
echo "  • .claude/agents/    - Agent configurations"
echo "  • .claude/templates/ - Document templates"  
echo "  • docs/audit/        - Audit evidence"
echo "  • infra/            - Azure Bicep templates"
echo ""
echo "🔗 Installed Git hooks:"
echo "  • pre-commit  - Architecture & naming validation"
echo "  • post-commit - Documentation updates"
echo ""
echo "🛠️  Available commands:"
echo "  • source .claude/agents/aliases.sh  - Load agent aliases"
echo "  • claude-docs      - Update documentation"
echo "  • claude-arch      - Validate architecture"
echo "  • claude-azure     - Validate Azure naming"
echo "  • claude-audit     - Check audit readiness"
echo "  • claude-validate  - Run all validations"
echo ""
echo "📝 VS Code integration:"
echo "  • Press Ctrl+Shift+P → Tasks: Run Task"
echo "  • Select any Claude agent task"
echo ""
echo "🚀 Quick start:"
echo "  1. source .claude/agents/aliases.sh"
echo "  2. claude-validate"
echo "  3. claude-generate-docs"
echo ""
echo "📊 Run audit check:"
echo "  .claude/quick-audit.sh"
echo ""
echo -e "${YELLOW}⚠️  Important:${NC}"
echo "  • Update 'specialization' in README.md for your project"
echo "  • Agents run on-demand, not as background services"
echo "  • Git hooks trigger agents automatically on commits"
echo ""
echo -e "${GREEN}Happy coding with Claude Code Subagents! 🤖${NC}"
EOF