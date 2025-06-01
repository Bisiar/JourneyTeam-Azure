# Computer Setup Documentation

This document outlines the environment configuration for development setup replication based on James's macOS development environment.

## System Information

- **OS**: macOS 15.5 (24F74)
- **Architecture**: ARM64 (Apple Silicon)
- **Shell**: Zsh (`/bin/zsh`)

## Core Development Tools

### Runtime Environments
- **.NET**: 10.0.100-preview.4.25258.110
- **Node.js**: v20.18.3 (managed via NVM)
- **Python**: 3.12.4
- **Java**: Java 11 (via `/usr/libexec/java_home -v11`)

### Development Tools
- **Git**: 2.33.0
- **VS Code**: 1.100.2 (ARM64)
- **Docker**: 28.1.1
- **Azure Developer CLI**: 1.16.1
- **Homebrew**: 4.5.3

## Package Management

### Homebrew Casks (Key Applications)
- `bleunlock`
- `chatgpt`
- `codeql`
- `font-fira-code`
- `powershell`
- `zulu@17`

### Homebrew Formulas (Key Tools)
- `azure-cli`
- `azure-functions-core-tools@4`
- `aztfexport`
- `terraform`
- `fastlane`
- `cliclick`

## Shell Configuration (`.zshrc`)

```bash
# Set up completions early
autoload -Uz compinit
compinit

# Bash-compatible completions
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Python path
export PATH="/usr/local/bin/python3:$PATH"

# Java configuration
export JAVA_HOME=$(/usr/libexec/java_home -v11)
export PATH=$JAVA_HOME/bin:$PATH

# .NET Core configuration
export DOTNET_ROOT=/usr/local/share/dotnet
export PATH="/usr/local/share/dotnet:$PATH"

# Docker CLI completions
fpath=(/Users/james/.docker/completions $fpath)

# Ruby environment
eval "$(rbenv init -)"

# LM Studio CLI
export PATH="$PATH:/Users/james/.cache/lm-studio/bin"

# Azure DevOps Personal Access Token
export NCNP_PAT="[REDACTED]"
```

## VS Code Configuration

### Key Settings (`settings.json`)
```json
{
    "git.autofetch": true,
    "files.autoSave": "afterDelay",
    "python.defaultInterpreterPath": "/usr/bin/python3",
    "go.toolsManagement.autoUpdate": true,
    "terminal.integrated.enableMultiLinePasteWarning": false,
    "github.copilot.chat.codeGeneration.instructions": [
        {
            "text": "Always add extensive comments to your code."
        }
    ]
}
```

### Key Bindings (`keybindings.json`)
```json
[
    {
        "key": "shift+enter",
        "command": "workbench.action.terminal.sendSequence",
        "args": {
            "text": "\\\r\n"
        },
        "when": "terminalFocus"
    }
]
```

## Setup Steps for New Computer

### 1. Install Core Tools
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install development tools
brew install git azure-cli azure-functions-core-tools@4 aztfexport terraform
brew install --cask powershell font-fira-code

# Install VS Code
brew install --cask visual-studio-code

# Install Docker
brew install --cask docker

# Install Azure Developer CLI
curl -fsSL https://aka.ms/install-azd.sh | bash
```

### 2. Install Runtime Environments
```bash
# Install .NET
wget https://dot.net/v1/dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --version latest

# Install NVM and Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 20.18.3
nvm use 20.18.3

# Install Python (if not already installed)
brew install python@3.12

# Install Java
brew install --cask zulu@17
```

### 3. Configure Shell
```bash
# Copy .zshrc configuration (see above)
# Restart terminal or run: source ~/.zshrc
```

### 4. Configure VS Code
- Copy `settings.json` and `keybindings.json` to `~/Library/Application Support/Code/User/`
- Install recommended extensions for development

### 5. Environment Variables
Set up required environment variables in `.zshrc`:
- `NCNP_PAT` for Azure DevOps access
- Path configurations for .NET, Java, Python

## Additional Development Tools

### JetBrains Suite

1. Visit the [JetBrains website](https://www.jetbrains.com/).
2. Download the JetBrains Toolbox App.
3. Use the Toolbox App to install Rider and WebStorm.
4. Activate your license or start a free trial.

### Beyond Compare

1. Go to the [Beyond Compare website](https://www.scootersoftware.com/).
2. Download the installer for your operating system.
3. Run the installer and follow the on-screen instructions.
4. Enter your license information if applicable.

### Azure Data Studio

1. Navigate to the [Azure Data Studio download page](https://docs.microsoft.com/en-us/sql/azure-data-studio/download-azure-data-studio).
2. Download and install the application.
3. Connect your databases as needed.

### Obsidian

1. Go to the [Obsidian website](https://obsidian.md/).
2. Download the installer for your OS.
3. Install the application and set up your vault.

### GitKraken

1. Visit the [GitKraken website](https://www.gitkraken.com/).
2. Download the installer for your OS.
3. Install GitKraken and sign in with your Git account.

### Postman

1. Head to the [Postman download page](https://www.postman.com/downloads/).
2. Download and install the application.
3. Sign in to sync your collections and environments.

### Cursor

1. Search for the Cursor software on its official website or a trusted software repository.
2. Download the installer for your OS.
3. Follow the installation instructions.

## Additional Notes

- System uses ARM64 architecture (Apple Silicon)
- Terminal configured with Shift+Enter for line continuation
- Auto-save enabled in VS Code
- Git auto-fetch enabled
- Docker completions configured for Zsh

### Git Configuration

1. Download and install Git from the [official website](https://git-scm.com/).
2. Configure your Git username and email using the terminal:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
