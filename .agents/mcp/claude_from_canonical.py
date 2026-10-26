#!/usr/bin/env python3
"""Transform canonical Cursor mcpServers JSON into Claude Code .mcp.json."""

from __future__ import annotations

import json
import os
import re
import sys
from typing import Any

# Cursor expands ${env:NAME}; Claude Code expands ${NAME}.
ENV_REF = re.compile(r"\$\{env:([A-Za-z_][A-Za-z0-9_]*)\}")


def rewrite_env(value: Any) -> Any:
    """Rewrite Cursor ${env:NAME} references to Claude Code ${NAME}."""
    if isinstance(value, str):
        return ENV_REF.sub(r"${\1}", value)
    if isinstance(value, list):
        return [rewrite_env(item) for item in value]
    if isinstance(value, dict):
        return {key: rewrite_env(item) for key, item in value.items()}
    return value


def canonical_to_claude(data: dict[str, Any]) -> dict[str, Any]:
    """Return a Claude Code project MCP document holding the stdio servers only.

    Remote (url) servers are left out. Claude Code reaches them as claude.ai
    connectors or user-scope entries, and a project entry would hide a
    connector with the same URL.
    """
    servers = data.get("mcpServers")
    if not isinstance(servers, dict):
        raise SystemExit("error: .agents/mcp.json must contain an mcpServers object")
    converted: dict[str, Any] = {}
    for name, spec in servers.items():
        if not isinstance(spec, dict):
            raise SystemExit(f"error: mcpServers.{name} must be an object")
        if "url" in spec:
            continue
        if "command" not in spec:
            raise SystemExit(f"error: mcpServers.{name} needs url (http) or command (stdio)")
        converted[name] = {"type": "stdio", **rewrite_env(spec)}
    return {"mcpServers": converted}


def dump_claude(data: dict[str, Any], dest: str) -> None:
    """Write Claude Code MCP JSON to dest, replacing an old symlink rather than its target."""
    if os.path.islink(dest):
        os.unlink(dest)
    with open(dest, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2)
        handle.write("\n")


def main() -> None:
    """CLI: canonical.json claude-mcp.json."""
    if len(sys.argv) != 3:
        raise SystemExit(f"usage: {sys.argv[0]} <canonical.json> <claude-mcp.json>")
    src, dst = sys.argv[1], sys.argv[2]
    with open(src, encoding="utf-8") as handle:
        canonical = json.load(handle)
    dump_claude(canonical_to_claude(canonical), dst)


if __name__ == "__main__":
    main()
