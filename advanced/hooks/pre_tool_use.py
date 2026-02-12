#!/usr/bin/env python3
"""
Pre-Tool Use Hook - Security validation before tool execution.

This hook validates tool calls before execution to prevent:
- Dangerous rm commands (rm -rf)
- Access to sensitive files (.env)
- Other security risks

Exit codes:
- 0: Allow execution (safe)
- 2: Block execution with error message
"""

import json
import re
import sys
from pathlib import Path
from typing import Any, Dict


def is_dangerous_rm_command(command: str) -> bool:
    """
    Detect dangerous rm commands that could delete important files.

    Detects patterns like:
    - rm -rf
    - rm -fr
    - rm --recursive --force
    - rm targeting dangerous paths (/, /*, ~, .., .)
    """
    # Normalize command (remove extra spaces)
    cmd = " ".join(command.split())

    # Pattern 1: rm with recursive and force flags
    rm_patterns = [
        r"\brm\s+(-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|--recursive\s+--force)",
        r"\brm\s+(-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*|--force\s+--recursive)",
        r"\brm\s+-[rR]f",
        r"\brm\s+-f[rR]",
    ]

    for pattern in rm_patterns:
        if re.search(pattern, cmd):
            # Check if targeting dangerous paths
            dangerous_paths = ["/", "/*", "~", "$HOME", "..", "*", "."]
            for path in dangerous_paths:
                if path in cmd:
                    return True

    # Pattern 2: rm -rf without obvious safe target
    if re.search(r"\brm\s+-[rR]f\s+[~/.]", cmd):
        return True

    return False


def is_env_file_access(tool_name: str, data: Dict[str, Any]) -> bool:
    """
    Detect attempts to access .env files (sensitive data).

    Allows .env.sample but blocks .env
    """
    if tool_name not in ["Read", "Edit", "MultiEdit", "Write", "Bash"]:
        return False

    # Check file paths
    file_path = data.get("file_path", "")
    if file_path and ".env" in file_path:
        # Allow .env.sample
        if ".env.sample" in file_path or ".env.example" in file_path:
            return False
        return True

    # Check bash commands
    if tool_name == "Bash":
        command = data.get("command", "")
        if ".env" in command:
            # Allow .env.sample
            if ".env.sample" in command or ".env.example" in command:
                return False
            # Block direct .env access
            env_patterns = [
                r"cat\s+\.env",
                r"echo\s+.*>\s*\.env",
                r"touch\s+\.env",
                r"cp\s+.*\.env",
                r"mv\s+.*\.env",
            ]
            for pattern in env_patterns:
                if re.search(pattern, command):
                    return True

    return False


def log_tool_call(data: Dict[str, Any]) -> None:
    """Log tool call to session-specific file."""
    session_id = data.get("sessionId", "unknown")
    log_dir = Path.cwd() / ".claude" / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    log_file = log_dir / f"pre_tool_use_{session_id}.json"

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
        pass  # Fail silently to not block execution


def main():
    """Main hook execution."""
    try:
        # Read tool call data from stdin
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        # No valid JSON, allow by default
        sys.exit(0)

    tool_name = data.get("tool", "")

    # Log the tool call
    log_tool_call(data)

    # Check for .env file access
    if is_env_file_access(tool_name, data):
        print("❌ Error: Access to .env files is blocked for security.", file=sys.stderr)
        print("Use .env.sample for templates.", file=sys.stderr)
        sys.exit(2)  # Block execution

    # Check for dangerous rm commands
    if tool_name == "Bash":
        command = data.get("command", "")
        if is_dangerous_rm_command(command):
            print("❌ Error: Dangerous rm command blocked.", file=sys.stderr)
            print(f"Command: {command}", file=sys.stderr)
            print("This could delete important system files.", file=sys.stderr)
            sys.exit(2)  # Block execution

    # Allow execution
    sys.exit(0)


if __name__ == "__main__":
    main()
