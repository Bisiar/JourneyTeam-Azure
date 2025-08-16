# WAF Documentation Agent

## Purpose
Automatically generate and maintain Microsoft Well-Architected Framework aligned documentation when code changes occur.

## Trigger
- File changes in `/src`, `/Domain`, `/Application`, `/Infrastructure`, `/Web`
- Git hooks: `post-commit`, `pre-push`
- Manual: `claude "Update WAF documentation"`

## Process

1. **Detect Specialization**
   ```bash
   # Check README for specialization type
   grep -i "specialization:" README.md
   ```

2. **Fetch Audit Checklist**
   ```bash
   # Download from GitHub if needed
   curl -O https://raw.githubusercontent.com/Bisiar/JourneyTeam-Azure/main/specializations/[SPECIALIZATION].pdf
   ```

3. **Analyze Code Structure**
   - Map onion architecture layers
   - Identify Azure resources in `/infra`
   - Check test coverage

4. **Generate Documentation**
   Update these 6-10 core documents:
   - `ARCHITECTURE.md` - Solution overview with onion layers
   - `OPERATIONS.md` - Deployment (azd up) and monitoring
   - `SECURITY.md` - Auth, data protection, compliance
   - `PERFORMANCE.md` - Targets, scaling, caching
   - `COST.md` - Resource sizing and optimization
   - `TESTING.md` - Test strategy and coverage
   - `DEPLOYMENT.md` - IaC and CI/CD
   - `AUDIT_EVIDENCE.md` - Specialization alignment
   - `README.md` - Project overview with specialization
   - `RUNBOOK.md` - Operations and troubleshooting

## Integration with MCP Servers

### SherpAI DevOps MCP
- Create work items for documentation gaps
- Track audit readiness as DevOps tasks

### Context7 MCP
- Persist documentation context across sessions
- Remember audit requirements and progress

## Example Prompt
```
claude "As the WAF Documentation Agent, analyze the current codebase and update documentation to align with the AI Platform on Microsoft Azure specialization. Focus on the 5 WAF pillars and keep to 10 documents maximum."
```