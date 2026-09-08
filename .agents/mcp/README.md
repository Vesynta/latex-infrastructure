# MCP configs

Team MCP client definitions for Cursor, VS Code / Copilot, and Claude Code. Workspace MCP runs **inside** the DevContainer.

## Source of truth

| Path                              | Role                                                                         |
| --------------------------------- | ---------------------------------------------------------------------------- |
| [`.agents/mcp.json`](../mcp.json) | **Canonical** (tracked). Edit this only.                                     |
| `.cursor/mcp.json`                | Tracked **symlink** to the canonical file (Cursor; same `mcpServers` schema) |
| `.mcp.json`                       | Tracked **symlink** to the canonical file (Claude Code; same schema)         |
| `.vscode/mcp.json`                | Generated for VS Code / Copilot (`servers` key; gitignored — schema differs) |

`make mcp-sync` refreshes the VS Code file and repairs the symlinks if they were deleted.

Devcontainers run the same via `postCreateCommand` in `.devcontainer/devcontainer.json`.

## Servers

| Name              | Purpose                                                                                                                                |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `vesynta`         | Vesynta Cloudflare Access MCP portal: `https://mcp.vesynta.com/mcp` (Google Workspace and GitHub are attached here, not in local JSON) |
| `aws-mcp`         | AWS MCP (local; portal-incompatible). Frankfurt URL with `?oauth=initialize`                                                           |
| `wrike`           | Wrike MCP (local; portal-incompatible). Client ID/secret from Passbolt via `${env:WRIKE_MCP_*}`                                        |
| `userback`        | Userback MCP (local; portal-incompatible)                                                                                              |
| `chrome-devtools` | Chrome DevTools MCP (stdio `npx`). DevContainer uses `--browser-url=http://127.0.0.1:9222`                                             |

**Read/docs-first:** use MCP to retrieve documentation and facts. Do **not** create/update/delete Access apps, tunnels, DNS, or other live resources via MCP. Disable write tools in the IDE when the session should be read-only.

## DevContainer / remote

MCP reads this workspace config **inside** the container. Laptop user `mcp.json`, Node, and env vars are unused for that window.

1. **Wrike:** copy Client ID and Secret from Passbolt into gitignored `.env` (`WRIKE_MCP_CLIENT_ID`, `WRIKE_MCP_CLIENT_SECRET`). Names are documented in `.env.example`. Rebuild the container after changing `.env`.
2. **OAuth callbacks** listen on the remote: **8787** (Cursor) and **33418** (VS Code). `.devcontainer/devcontainer.json` auto-forwards those onto the laptop. If the browser stays blank after Allow, check the Ports view.
3. **Chrome** stays on the laptop. Start it with `--remote-debugging-port=9222`, then **reverse-forward** `9222` so container `127.0.0.1:9222` reaches laptop Chrome. Do not combine `--autoConnect` with `--browser-url`.

`npx` (Chrome MCP) is already on PATH in the `dev` image.

## Make targets

```bash
make mcp-sync         # repair symlinks + regenerate .vscode/mcp.json
make mcp-check-config # structure only (pre-commit / make check)
make mcp-check        # structure + portal reachability
make mcp-auth-help    # print Access OAuth steps (does not store credentials)
```

There is **no** `make mcp-auth` that logs you in. Portal auth is interactive Cloudflare Access OAuth inside the IDE.

## Team setup

1. `make mcp-sync`
2. Open the repo in a DevContainer and enable workspace MCP servers
3. Complete Access login when prompted for `mcp.vesynta.com`
4. Complete aws-mcp / wrike / userback OAuth; prefer least-privilege and disable write tools if needed
5. Never commit tokens, service tokens, or cookies into `mcp.json` or the repo

## Troubleshooting

| Symptom                                  | Likely cause                                                                                                         |
| ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `401` / Access login loop                | Expected until you complete IDE OAuth; confirm you have Access to the portal app                                     |
| Portal “unreachable” in `make mcp-check` | Network / DNS / VPN; verify `https://mcp.vesynta.com`                                                                |
| Missing `.cursor/mcp.json`               | Restore the tracked symlink, or run `make mcp-sync`                                                                  |
| VS Code ignores servers                  | Run `make mcp-sync` (`.vscode/mcp.json` is gitignored; CI validates the transform without that file)                 |
| Wrike never authenticates                | `.env` missing `WRIKE_MCP_*`; rebuild after setting; fully restart the IDE window                                    |
| OAuth Allow then blank page              | Forward remote **8787** (Cursor) or **33418** (VS Code) onto the laptop                                              |
| Chrome MCP cannot attach                 | Laptop Chrome on `9222` plus **reverse-forward** of `9222` into the container                                        |
| Remote `url` + Access flaky              | In `.agents/mcp.json`, switch the portal entry to `npx -y mcp-remote@latest <portal-url>` and re-run `make mcp-sync` |

## Out of scope (for now)

- Direct `https://mcp.cloudflare.com/mcp` (bypasses portal governance)
- Google Workspace or GitHub URLs in local `mcp.json` (reach those through `vesynta`)
- Code Mode (`?codemode=search_and_execute`) as the portal URL
- Committing Access service tokens for machine auth
