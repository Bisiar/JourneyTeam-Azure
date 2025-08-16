# Security Cleanup Required Before Publishing

## ⚠️ CRITICAL: Sensitive Information Found

The following sensitive information was found and needs to be removed or replaced before publishing to the public repository:

### 1. Environment Variables in .zshrc (Lines 131, 135-136, 170-171)
- **ANTHROPIC_API_KEY**: `sk-ant-api03-...` (Line 131)
- **JTOP_PAT_TOKEN**: Personal Access Token (Lines 135, 170) 
- **NCNP_PAT_TOKEN**: Personal Access Token (Lines 136, 171)

**Action Required**: These are in your personal `.zshrc` file, not in the repo, so they won't be published. However, ensure you don't commit any file that references these actual values.

### 2. Files in Repository That Need Cleaning

#### AI-Computer-Setup.md
This file contains several references to tokens and secrets, but they appear to be **placeholder examples** like:
- `"your-telerik-key-here"`
- `"your-github-token"`
- `"your-figma-token"`
- `"your-pat-token"`

**Status**: ✅ These are safe as they're clearly marked as examples.

#### Files That Are Safe
The following files only contain example/placeholder values or documentation about security:
- `README.md` - Contains only example placeholders like `"your-client-secret"`
- `OAuth-Tokens-Guide.md` - Educational content about tokens
- `B2C.md` - Code examples with generic variable names
- `Computer-Setup.md` - References to PAT tokens but no actual values

### 3. Git Configuration to Check
Your Git configuration shows an SSH signing key:
- `user.signingkey=ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILINO35wVeXK10zes/FQyLDTl/p5419qV8ZXBGJIiR6O`

**Status**: ✅ This is your PUBLIC SSH key for commit signing, which is safe to share.

## Recommended Actions Before Publishing

### 1. Add .gitignore Entries
Ensure these are in your `.gitignore`:
```
.env
.env.local
*.key
*.pem
.claude/settings.local.json
.azure/
**/appsettings.Development.json
**/*PAT*
**/*TOKEN*
**/*SECRET*
```

### 2. Review Azure Configuration
The `.azure/` directory may contain environment-specific configurations. Check if this should be excluded.

### 3. Double-Check AI-Computer-Setup.md
While the tokens appear to be examples, verify that none of the "example" tokens are real by searching for:
- Any string starting with `sk-ant-`
- Any base64-encoded strings that might be real tokens
- Any Azure DevOps PAT tokens (they have a specific format)

### 4. Clean Git History (If Needed)
If you previously committed any real secrets, you'll need to clean the Git history:
```bash
# Use BFG Repo-Cleaner or git filter-branch
# Example with BFG:
bfg --replace-text passwords.txt repo.git
```

## Final Checklist

- [ ] Verify all tokens in documentation are clearly marked as examples
- [ ] Check `.azure/` directory for sensitive configs
- [ ] Ensure `.gitignore` covers all sensitive file patterns
- [ ] Review `claude-agents/` files for any hardcoded values
- [ ] Confirm no real API keys, passwords, or tokens in any committed files
- [ ] Consider adding a `SECURITY.md` file explaining the security model

## Safe to Publish

After reviewing, the repository appears mostly safe to publish with these caveats:
1. **AI-Computer-Setup.md** contains many example tokens - ensure they're all fake
2. Your personal `.zshrc` is NOT in the repo, so those secrets are safe
3. The SSH signing key is a PUBLIC key and safe to share

## Recommendation

Before publishing, run this command to do a final check:
```bash
# Search for potential secrets (adjust patterns as needed)
grep -r -E "(sk-ant-|pat_|ghp_|api[_-]key|password|secret|token)" \
  --exclude-dir=.git \
  --exclude-dir=node_modules \
  --exclude="*.md" \
  /Users/james/Source/bisiar.github.com/JourneyTeam-Azure/ 2>/dev/null | \
  grep -v -E "(your-|example|placeholder|fake|dummy|xxx)"
```

This will find any potential secrets that aren't clearly marked as examples.