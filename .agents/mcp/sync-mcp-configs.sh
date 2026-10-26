#!/usr/bin/env bash
# Materialize IDE MCP client configs from the canonical .agents/mcp.json.
# Edit only .agents/mcp.json, then run: make mcp-sync
#
# Cursor reads the same schema, so it gets a committed symlink.
# VS Code / Copilot wants a top-level "servers" key, so that file is generated.
# Claude Code wants "type" and ${NAME} env syntax, so .mcp.json is generated
# with the stdio servers only.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CANONICAL="${ROOT}/.agents/mcp.json"
VSCODE_TRANSFORM="${ROOT}/.agents/mcp/vscode_from_canonical.py"
CLAUDE_TRANSFORM="${ROOT}/.agents/mcp/claude_from_canonical.py"

for required in "${CANONICAL}" "${VSCODE_TRANSFORM}" "${CLAUDE_TRANSFORM}"; do
  if [[ ! -f "${required}" ]]; then
    echo "error: missing ${required}" >&2
    exit 1
  fi
done

mkdir -p "${ROOT}/.cursor" "${ROOT}/.vscode"

# Relative target so the link works on any clone path.
ln -sfn ../.agents/mcp.json "${ROOT}/.cursor/mcp.json"

python3 "${VSCODE_TRANSFORM}" "${CANONICAL}" "${ROOT}/.vscode/mcp.json"
python3 "${CLAUDE_TRANSFORM}" "${CANONICAL}" "${ROOT}/.mcp.json"

echo "Synced MCP configs from .agents/mcp.json:"
echo "  .cursor/mcp.json  (symlink)"
echo "  .vscode/mcp.json  (generated, servers key)"
echo "  .mcp.json         (generated, Claude Code, stdio servers only)"
echo "Next: connect the servers in your IDE's MCP settings"
