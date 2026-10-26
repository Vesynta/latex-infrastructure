#!/usr/bin/env python3
"""Transform canonical Cursor mcpServers JSON into VS Code servers JSON."""

from __future__ import annotations

import json
import sys
from typing import Any


def server_to_vscode(name: str, spec: Any) -> dict[str, Any]:
    """Convert one Cursor server spec into a VS Code servers entry."""
    if not isinstance(spec, dict):
        raise SystemExit(f"error: mcpServers.{name} must be an object")
    out = dict(spec)
    auth = out.pop("auth", None)
    if auth is not None:
        if not isinstance(auth, dict):
            raise SystemExit(f"error: mcpServers.{name}.auth must be an object")
        client_id = auth.get("CLIENT_ID")
        client_secret = auth.get("CLIENT_SECRET")
        if not client_id or not client_secret:
            raise SystemExit(f"error: mcpServers.{name}.auth needs CLIENT_ID and CLIENT_SECRET")
        out["oauth"] = {
            "clientId": client_id,
            "clientSecret": client_secret,
        }
    if "url" in out:
        return {"type": "http", **out}
    if "command" in out:
        return {"type": "stdio", **out}
    raise SystemExit(f"error: mcpServers.{name} needs url (http) or command (stdio)")


def canonical_to_vscode(data: dict[str, Any]) -> dict[str, Any]:
    """Return a VS Code MCP document with a top-level servers key."""
    servers = data.get("mcpServers")
    if not isinstance(servers, dict):
        raise SystemExit("error: .agents/mcp.json must contain an mcpServers object")
    converted = {name: server_to_vscode(name, spec) for name, spec in servers.items()}
    return {"servers": converted}


def dump_vscode(data: dict[str, Any], dest: str) -> None:
    """Write VS Code MCP JSON to dest."""
    with open(dest, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2)
        handle.write("\n")


def main() -> None:
    """CLI: canonical.json vscode-mcp.json."""
    if len(sys.argv) != 3:
        raise SystemExit(f"usage: {sys.argv[0]} <canonical.json> <vscode-mcp.json>")
    src, dst = sys.argv[1], sys.argv[2]
    with open(src, encoding="utf-8") as handle:
        canonical = json.load(handle)
    dump_vscode(canonical_to_vscode(canonical), dst)


if __name__ == "__main__":
    main()
