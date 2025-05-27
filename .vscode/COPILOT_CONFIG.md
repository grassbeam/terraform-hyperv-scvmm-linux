# VS Code Extension Configuration

This file contains additional settings to prevent confirmation prompts when using GitHub Copilot.

## Manual Steps to Completely Disable Prompts:

### 1. Trust the Workspace Permanently
- Open Command Palette (`Cmd+Shift+P`)
- Run: `Workspaces: Manage Workspace Trust`
- Click "Trust" for this workspace

### 2. Disable Security Features (Global Settings)
Add these to your global VS Code settings (`Cmd+,` → Open Settings JSON):

```json
{
  "security.workspace.trust.enabled": false,
  "security.workspace.trust.banner": "never",
  "security.workspace.trust.startupPrompt": "never",
  "security.workspace.trust.emptyWindow": false,
  "terminal.integrated.confirmOnExit": "never",
  "terminal.integrated.confirmOnKill": "never", 
  "terminal.integrated.allowChords": false,
  "github.copilot.advanced": {
    "debug.overrideChatEngine": "gpt-4"
  }
}
```

### 3. Use Direct Terminal Execution
Instead of relying on VS Code terminal, you can:

```bash
# Run git operations directly
./scripts/git_update.sh

# Run terraform operations directly  
make setup
make test
make shutdown
```

### 4. Alternative: Use VS Code Tasks
Create tasks in `.vscode/tasks.json` for common operations:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Git Push All",
      "type": "shell",
      "command": "./scripts/git_update.sh",
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    }
  ]
}
```

### 5. Restart VS Code
After changing settings, restart VS Code to ensure all configurations take effect.

## Troubleshooting

If prompts still appear:
1. Check that workspace is trusted
2. Verify global settings are applied
3. Try using the direct scripts instead of Copilot terminal commands
4. Use VS Code tasks for automated operations
