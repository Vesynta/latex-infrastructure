#!/usr/bin/env bash
# Verify canonical MCP config, IDE symlinks / generated file, and portal reachability.
# Structure-only (pre-commit): MCP_CHECK_OFFLINE=1
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CANONICAL="${ROOT}/.agents/mcp.json"
TRANSFORM="${ROOT}/.agents/mcp/vscode_from_canonical.py"
VSCODE_MCP="${ROOT}/.vscode/mcp.json"
PORTAL_URL="https://mcp.vesynta.com/mcp"
CHROME_BROWSER_URL="http://127.0.0.1:9222"
FAILED=0
OFFLINE=0
if [[ "${MCP_CHECK_OFFLINE:-}" == "1" || "${MCP_CHECK_OFFLINE:-}" == "true" ]]; then
  OFFLINE=1
fi

pass() { echo "OK  $*"; }
fail() { echo "FAIL $*"; FAILED=1; }

canonical_resolved=""
if [[ ! -f "${CANONICAL}" ]]; then
  fail "missing ${CANONICAL}"
else
  pass "canonical ${CANONICAL}"
  canonical_resolved="$(readlink -f "${CANONICAL}")"
fi

if [[ ! -f "${TRANSFORM}" ]]; then
  fail "missing ${TRANSFORM}"
fi

# Structural assertions against the canonical file and generated VS Code JSON.
if [[ -f "${CANONICAL}" && -f "${TRANSFORM}" ]]; then
  if python3 - "${CANONICAL}" "${TRANSFORM}" "${VSCODE_MCP}" "${PORTAL_URL}" "${CHROME_BROWSER_URL}" <<'PY'
import json
import sys
from pathlib import Path

canonical_path, transform_path, vscode_path, portal_url, chrome_url = sys.argv[1:6]
sys.path.insert(0, str(Path(transform_path).parent))
from vscode_from_canonical import canonical_to_vscode  # noqa: E402

REQUIRED = (
    "vesynta",
    "aws-mcp",
    "wrike",
    "userback",
    "chrome-devtools",
)
failed = 0


def fail(msg: str) -> None:
    global failed
    print(f"FAIL {msg}")
    failed = 1


def ok(msg: str) -> None:
    print(f"OK  {msg}")


with open(canonical_path, encoding="utf-8") as handle:
    canonical = json.load(handle)

raw = Path(canonical_path).read_text(encoding="utf-8")
if "codemode" in raw:
    fail("canonical must not use Code Mode (codemode query param)")
else:
    ok("no Code Mode query param")

servers = canonical.get("mcpServers")
if not isinstance(servers, dict):
    fail("canonical must contain an mcpServers object")
    sys.exit(1)

missing = [name for name in REQUIRED if name not in servers]
if missing:
    fail(f"canonical missing servers: {', '.join(missing)}")
else:
    ok(f"required servers present ({', '.join(REQUIRED)})")

vesynta = servers.get("vesynta") or {}
if vesynta.get("url") != portal_url:
    fail(f"vesynta url must be {portal_url} (got {vesynta.get('url')!r})")
else:
    ok("vesynta portal URL")

chrome = servers.get("chrome-devtools") or {}
args = chrome.get("args") if isinstance(chrome, dict) else None
if not isinstance(args, list):
    fail("chrome-devtools args missing")
else:
    joined = " ".join(str(a) for a in args)
    if "--autoConnect" in args or "--autoConnect" in joined:
        fail("chrome-devtools must not use --autoConnect in the DevContainer")
    expected_flag = f"--browser-url={chrome_url}"
    if expected_flag not in args:
        fail(f"chrome-devtools must include {expected_flag}")
    else:
        ok("chrome-devtools --browser-url (no --autoConnect)")

wrike = servers.get("wrike") or {}
auth = wrike.get("auth") if isinstance(wrike, dict) else None
if not isinstance(auth, dict):
    fail("wrike.auth missing")
elif auth.get("CLIENT_ID") != "${env:WRIKE_MCP_CLIENT_ID}":
    fail("wrike.auth.CLIENT_ID must use ${env:WRIKE_MCP_CLIENT_ID}")
elif auth.get("CLIENT_SECRET") != "${env:WRIKE_MCP_CLIENT_SECRET}":
    fail("wrike.auth.CLIENT_SECRET must use ${env:WRIKE_MCP_CLIENT_SECRET}")
else:
    ok("wrike auth uses env placeholders")

# If a terraform server is present (infrastructure only), it must be pinned.
tf = servers.get("terraform") or {}
if tf:
    tf_args = tf.get("args") if isinstance(tf, dict) else None
    tf_image = tf_args[-1] if isinstance(tf_args, list) and tf_args else ""
    if not tf_image:
        fail("terraform MCP image missing")
    elif tf_image.endswith(":latest"):
        fail(f"terraform MCP image must be pinned (got {tf_image})")
    else:
        ok(f"terraform MCP image pinned ({tf_image})")

# .vscode/mcp.json is gitignored. CI / fresh clones will not have it.
# Always validate the transform; compare the on-disk file only when present.
expected = canonical_to_vscode(canonical)
vscode_path_obj = Path(vscode_path)
if vscode_path_obj.is_file():
    with open(vscode_path, encoding="utf-8") as handle:
        actual = json.load(handle)
    if actual != expected:
        fail(".vscode/mcp.json does not match canonical transform (run: make mcp-sync)")
    else:
        ok("generated .vscode/mcp.json matches transform")
    vscode_doc = actual
else:
    ok("generated .vscode/mcp.json absent (gitignored; validating transform)")
    vscode_doc = expected

if "servers" not in vscode_doc or "mcpServers" in vscode_doc:
    fail("VS Code MCP JSON must use top-level servers key")
else:
    ok("VS Code MCP JSON uses servers key")

vs_servers = vscode_doc.get("servers") or {}
type_missing = [
    name
    for name, spec in vs_servers.items()
    if not isinstance(spec, dict) or spec.get("type") not in {"http", "stdio"}
]
if type_missing:
    fail(f"VS Code MCP JSON missing type on: {', '.join(type_missing)}")
else:
    ok("VS Code MCP JSON entries have type")

vs_wrike = vs_servers.get("wrike") or {}
if "auth" in vs_wrike:
    fail("VS Code MCP JSON wrike must not keep Cursor auth")
elif not isinstance(vs_wrike.get("oauth"), dict):
    fail("VS Code MCP JSON wrike must use oauth")
else:
    ok("VS Code MCP JSON wrike uses oauth")

sys.exit(failed)
PY
  then
    :
  else
    FAILED=1
  fi
fi

assert_symlink_to_canonical() {
  local rel="$1"
  local path="${ROOT}/${rel}"
  if [[ ! -L "${path}" ]]; then
    fail "${rel} should be a symlink to .agents/mcp.json (run: make mcp-sync)"
    return
  fi
  if [[ -z "${canonical_resolved}" ]]; then
    fail "${rel}: cannot resolve canonical target"
    return
  fi
  local resolved
  resolved="$(readlink -f "${path}")"
  if [[ "${resolved}" != "${canonical_resolved}" ]]; then
    fail "${rel} does not resolve to ${CANONICAL}"
  else
    pass "symlink ${rel}"
  fi
}

assert_symlink_to_canonical ".cursor/mcp.json"
assert_symlink_to_canonical ".mcp.json"

if [[ "${OFFLINE}" -eq 1 ]]; then
  pass "portal smoke skipped (MCP_CHECK_OFFLINE)"
else
  # Access-gated portal: 401/302/403 means the edge is up; connection errors are failures.
  set +e
  HTTP_CODE="$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 10 --max-time 20 "${PORTAL_URL}" 2>/dev/null)"
  curl_status=$?
  set -e
  if [[ "${curl_status}" -ne 0 || -z "${HTTP_CODE}" ]]; then
    HTTP_CODE="000"
  fi
  case "${HTTP_CODE}" in
    401|302|403|200)
      pass "portal reachable (HTTP ${HTTP_CODE})"
      ;;
    000)
      fail "portal unreachable (connection failed): ${PORTAL_URL}"
      ;;
    *)
      fail "portal unexpected HTTP ${HTTP_CODE}: ${PORTAL_URL}"
      ;;
  esac
fi

if [[ "${FAILED}" -ne 0 ]]; then
  echo "mcp-check failed" >&2
  exit 1
fi
echo "mcp-check passed"
