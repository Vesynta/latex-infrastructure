# MCP configs

Workspace [Model Context Protocol](https://modelcontextprotocol.io/) servers for Cursor, VS Code, and Claude Code. They run **inside** the Dev Container and need no sign-in.

## Source of truth

| Path                              | Role                                                       |
| --------------------------------- | ---------------------------------------------------------- |
| [`.agents/mcp.json`](../mcp.json) | **Canonical** (tracked). Edit this only.                   |
| `.cursor/mcp.json`                | Tracked symlink to the canonical file (Cursor)             |
| `.vscode/mcp.json`                | Generated for VS Code (`servers` key; gitignored)          |
| `.mcp.json`                       | Generated for Claude Code (gitignored): stdio servers only |

`make mcp-sync` regenerates `.vscode/mcp.json` and `.mcp.json`, and repairs the Cursor symlink. The Dev Container runs it through `make setup`.

## Servers

| Name     | Purpose                                                                                                                                              |
| -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `drawio` | draw.io tool server (`npx -y @drawio/mcp`). Returns a link that opens the diagram in the draw.io editor; the diagram travels in the link's fragment. |

Only public servers that need no sign-in belong in this file. Add personal servers to your **user** MCP config inside the container instead: Cursor `~/.cursor/mcp.json`, VS Code **MCP: Open Remote User Configuration**, or Claude Code `claude mcp add --scope user`. The Dev Container keeps `~/.cursor` in a named volume, so Cursor's user config survives a rebuild.

## Troubleshooting

| Symptom                                           | What to do                                                                           |
| ------------------------------------------------- | ------------------------------------------------------------------------------------ |
| VS Code or Claude Code shows no workspace servers | Run `make mcp-sync`. Claude Code asks you to approve project servers the first time. |
| `spawn npx ENOENT`                                | The Dev Container image provides `npx`. Rebuild the container.                       |
