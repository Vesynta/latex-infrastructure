#!/usr/bin/env bash
# Materialize IDE MCP client configs from the canonical .agents/mcp.json.
# Edit only .agents/mcp.json, then run: make mcp-sync
#
# Same-schema clients (Cursor, Claude Code) get committed symlinks.
# VS Code / Copilot wants a top-level "servers" key, so that file is generated.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CANONICAL="${ROOT}/.agents/mcp.json"
TRANSFORM="${ROOT}/.agents/mcp/vscode_from_canonical.py"

if [[ ! -f "${CANONICAL}" ]]; then
  echo "error: missing canonical MCP config: ${CANONICAL}" >&2
  exit 1
fi

if [[ ! -f "${TRANSFORM}" ]]; then
  echo "error: missing VS Code transform: ${TRANSFORM}" >&2
  exit 1
fi

mkdir -p "${ROOT}/.cursor" "${ROOT}/.vscode"

# Relative targets so the links work on any clone path.
ln -sfn ../.agents/mcp.json "${ROOT}/.cursor/mcp.json"
ln -sfn .agents/mcp.json "${ROOT}/.mcp.json"

python3 "${TRANSFORM}" "${CANONICAL}" "${ROOT}/.vscode/mcp.json"

echo "Synced MCP configs from .agents/mcp.json:"
echo "  .cursor/mcp.json  (symlink)"
echo "  .mcp.json         (symlink)"
echo "  .vscode/mcp.json  (generated, servers key)"
echo "Next: make mcp-auth-help  (Access OAuth happens in your IDE)"
