---
name: git-guardrails-codex
description: Set up Codex project hooks that block dangerous GitHub CLI (`gh`) operations before shell execution. Use when the user wants Codex guardrails for `gh`, wants to prevent accidental PR merges, issue/release deletion, repo deletion/archive/transfer, mutating `gh api` calls, workflow disabling, or other destructive GitHub CLI actions.
---

# Git Guardrails for Codex

Set up a Codex `PreToolUse` hook that blocks dangerous `gh` commands before Codex executes them.

## What Gets Blocked

The bundled hook blocks high-risk GitHub CLI operations, including:

- `gh pr merge` and `gh pr close`
- `gh issue close` and `gh issue delete`
- `gh repo delete`, `gh repo archive`, `gh repo rename`, and `gh repo transfer`
- `gh release delete`
- `gh workflow disable`
- `gh run cancel` and `gh run delete`
- `gh secret set/delete` and `gh variable set/delete`
- `gh label delete`
- mutating `gh api` calls using `DELETE`, `POST`, `PATCH`, or `PUT`

Keep read-only commands such as `gh pr view`, `gh issue list`, and `gh run view` allowed.

## Install

### 1. Choose Scope

Default to project-local installation unless the user explicitly asks for global setup.

Project-local files:

```text
.codex/hooks/block-dangerous-gh.ps1
.codex/hooks.json
.codex/config.toml
```

Global installation is possible but should be handled cautiously because Codex config locations may differ by environment. Prefer project-local hooks for reproducibility.

### 2. Copy the Script

Copy [scripts/block-dangerous-gh.ps1](scripts/block-dangerous-gh.ps1) into the target repo:

```text
.codex/hooks/block-dangerous-gh.ps1
```

Create `.codex/hooks/` if needed.

### 3. Enable Codex Hooks

Ensure `.codex/config.toml` contains:

```toml
[features]
codex_hooks = true
```

Preserve any existing config keys.

### 4. Add the PreToolUse Hook

Merge this hook into `.codex/hooks.json`. Do not overwrite existing hooks.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "^Bash$",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$(git rev-parse --show-toplevel)/.codex/hooks/block-dangerous-gh.ps1\"",
            "timeout": 30,
            "statusMessage": "Checking GitHub CLI guardrails"
          }
        ]
      }
    ]
  }
}
```

If the repo already has a `PreToolUse` entry for the shell tool, append this hook command to that entry's `hooks` array. If the repo uses a different shell tool matcher, adapt the matcher to the existing Codex hook convention in that repo.

### 5. Customize Patterns

Ask whether the user wants to add or remove blocked commands. Edit the copied script's `$DangerousPatterns` list only for intentional policy changes.

### 6. Verify

Run the script directly with representative JSON:

```powershell
'{"tool_input":{"command":"gh pr merge 123 --squash"}}' | powershell -NoProfile -ExecutionPolicy Bypass -File .codex/hooks/block-dangerous-gh.ps1
```

Expected result: exit code `2` and a `BLOCKED` message on stderr.

Also verify a read-only command exits `0`:

```powershell
'{"tool_input":{"command":"gh pr view 123"}}' | powershell -NoProfile -ExecutionPolicy Bypass -File .codex/hooks/block-dangerous-gh.ps1
```
