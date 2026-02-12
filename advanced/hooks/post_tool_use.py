#!/usr/bin/env python3
"""
Post-Tool Use Hook - Audit logging after tool execution.

This hook logs all tool executions for:
- Audit trails
- Performance analysis
- Debugging
- Compliance

Always succeeds (exit 0) to not block workflow.
"""

import json
import sys
from pathlib import Path
from typing import Any, Dict


def log_tool_execution(data: Dict[str, Any]) -> None:
    """Log tool execution to session-specific file."""
    session_id = data.get("sessionId", "unknown")
    log_dir = Path.cwd() / ".claude" / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    log_file = log_dir / f"post_tool_use_{session_id}.json"

    # Load existing logs
    logs = []
    if log_file.exists():
        try:
            with open(log_file, "r") as f:
                logs = json.load(f)
        except (json.JSONDecodeError, IOError):
            logs = []

    # Append new log
    logs.append(data)

    # Save logs
    try:
        with open(log_file, "w") as f:
            json.dump(logs, f, indent=2)
    except IOError:
        # Fail silently
        pass


def main():
    """Main hook execution."""
    try:
        # Read tool execution data from stdin
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        # No valid JSON, exit gracefully
        sys.exit(0)

    # Log the execution
    log_tool_execution(data)

    # Always succeed
    sys.exit(0)


if __name__ == "__main__":
    main()
