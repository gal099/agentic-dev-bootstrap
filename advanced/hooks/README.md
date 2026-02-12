# Advanced Hooks

Security and monitoring hooks for Claude Code execution.

## Available Hooks

### `pre_tool_use.py`
**Security Gatekeeper** - Validates tool calls before execution.

**Blocks:**
- Dangerous `rm -rf` commands targeting system paths
- Direct access to `.env` files (allows `.env.sample`)
- Other security risks

**Logs:**
- All tool calls to `.claude/logs/pre_tool_use_{sessionId}.json`

**Exit Codes:**
- `0`: Allow execution
- `2`: Block execution with error message

### `post_tool_use.py`
**Audit Logger** - Records all tool executions.

**Logs:**
- Complete tool execution data
- Results and errors
- Timing information
- Saved to `.claude/logs/post_tool_use_{sessionId}.json`

**Always succeeds** - Never blocks workflow

## Installation

To enable hooks in your project, update `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": ["Read", "Write", "Edit", "Bash(git:*)"],
    "deny": ["Bash(rm -rf:*)", "Bash(git push --force:*)"]
  },
  "hooks": {
    "PreToolUse": [{
      "hooks": [{
        "type": "command",
        "command": "uv run $CLAUDE_PROJECT_DIR/.claude/hooks/pre_tool_use.py || true"
      }]
    }],
    "PostToolUse": [{
      "hooks": [{
        "type": "command",
        "command": "uv run $CLAUDE_PROJECT_DIR/.claude/hooks/post_tool_use.py || true"
      }]
    }]
  }
}
```

## Log Files

Logs are stored in `.claude/logs/`:
- `pre_tool_use_{sessionId}.json` - Pre-execution validations
- `post_tool_use_{sessionId}.json` - Post-execution audit trail

Add to `.gitignore`:
```
.claude/logs/
```

## Customization

You can extend these hooks by:
1. Adding more validation rules in `pre_tool_use.py`
2. Adding more logging in `post_tool_use.py`
3. Creating new hooks for other lifecycle events

See Claude Code documentation for all available hook types.
