#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

CODEX_MARKETPLACE=".agents/plugins/marketplace.json"
CLAUDE_MARKETPLACE=".claude-plugin/marketplace.json"
CODEX_PLUGIN_VALIDATOR="${CODEX_PLUGIN_VALIDATOR:-$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py}"

section() {
  printf '\n==> %s\n' "$1"
}

ok() {
  printf 'OK: %s\n' "$1"
}

warn() {
  printf 'WARN: %s\n' "$1" >&2
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

require_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "missing required file: $path"
}

require_dir() {
  local path="$1"
  [[ -d "$path" ]] || fail "missing required directory: $path"
}

require_command() {
  local command_name="$1"
  local install_hint="$2"
  command -v "$command_name" >/dev/null 2>&1 || fail "missing command '$command_name'. $install_hint"
}

json_check() {
  local path="$1"
  python3 -m json.tool "$path" >/dev/null || fail "invalid JSON: $path"
}

mcp_endpoint() {
  local mcp_json="$1"
  python3 - "$mcp_json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    data = json.load(fh)
servers = data.get("mcpServers", {})
urls = [s.get("url") for s in servers.values() if isinstance(s, dict) and s.get("url")]
if not urls:
    sys.exit(f"no mcpServers[*].url found in {sys.argv[1]}")
print(urls[0])
PY
}

section "Prerequisites"
require_command python3 "Install Python 3 and rerun this script."
require_command claude "Install Claude Code CLI so 'claude plugin validate' is available."
require_command grep "Install grep and rerun this script."

RUN_CODEX=1
if [[ "${SKIP_CODEX:-0}" == "1" ]]; then
  RUN_CODEX=0
  warn "SKIP_CODEX=1 set; skipping Codex plugin validation"
elif [[ ! -f "$CODEX_PLUGIN_VALIDATOR" ]]; then
  RUN_CODEX=0
  warn "Codex validator not found at $CODEX_PLUGIN_VALIDATOR; skipping Codex validation (set CODEX_PLUGIN_VALIDATOR to override)"
fi
ok "required commands are available"

section "Marketplace JSON"
require_file "$CODEX_MARKETPLACE"
require_file "$CLAUDE_MARKETPLACE"
json_check "$CODEX_MARKETPLACE"
json_check "$CLAUDE_MARKETPLACE"
claude plugin validate "$CLAUDE_MARKETPLACE" --strict
ok "marketplace JSON valid; Claude marketplace passed schema validation"

PLUGIN_PATHS_FILE="$(mktemp)"
trap 'rm -f "$PLUGIN_PATHS_FILE"' EXIT

python3 - <<'PY' > "$PLUGIN_PATHS_FILE"
import json
import os
from pathlib import Path

marketplaces = [
    Path(".agents/plugins/marketplace.json"),
    Path(".claude-plugin/marketplace.json"),
]

paths = []

with marketplaces[0].open(encoding="utf-8") as fh:
    codex = json.load(fh)
for index, plugin in enumerate(codex.get("plugins", [])):
    source = plugin.get("source")
    if not isinstance(source, dict):
        raise SystemExit(f"{marketplaces[0]} plugins[{index}].source must be an object")
    path = source.get("path")
    if not isinstance(path, str) or not path.strip():
        raise SystemExit(f"{marketplaces[0]} plugins[{index}].source.path must be a non-empty string")
    paths.append(path)

with marketplaces[1].open(encoding="utf-8") as fh:
    claude = json.load(fh)
for index, plugin in enumerate(claude.get("plugins", [])):
    path = plugin.get("source")
    if not isinstance(path, str) or not path.strip():
        raise SystemExit(f"{marketplaces[1]} plugins[{index}].source must be a non-empty string")
    paths.append(path)

normalized = []
for raw_path in paths:
    if os.path.isabs(raw_path):
        raise SystemExit(f"plugin source must be relative, got absolute path: {raw_path}")
    norm = os.path.normpath(raw_path)
    if norm == "." or norm.startswith(".."):
        raise SystemExit(f"plugin source must stay inside the repository: {raw_path}")
    normalized.append(norm)

for path in sorted(set(normalized)):
    print(path)
PY

[[ -s "$PLUGIN_PATHS_FILE" ]] || fail "no plugin paths found in marketplace files"
ok "plugin paths discovered"

section "Plugin Package Structure"
while IFS= read -r plugin_dir; do
  require_dir "$plugin_dir"
  require_file "$plugin_dir/.codex-plugin/plugin.json"
  require_file "$plugin_dir/.claude-plugin/plugin.json"
  require_file "$plugin_dir/.mcp.json"
  require_dir "$plugin_dir/skills"
  find "$plugin_dir/skills" -mindepth 2 -maxdepth 2 -name SKILL.md -type f | grep -q . \
    || fail "plugin has no bundled skills/*/SKILL.md: $plugin_dir"
  ok "$plugin_dir has required plugin files"
done < "$PLUGIN_PATHS_FILE"

section "Plugin JSON"
json_check "$CODEX_MARKETPLACE"
json_check "$CLAUDE_MARKETPLACE"
while IFS= read -r plugin_dir; do
  json_check "$plugin_dir/.codex-plugin/plugin.json"
  json_check "$plugin_dir/.claude-plugin/plugin.json"
  json_check "$plugin_dir/.mcp.json"
done < "$PLUGIN_PATHS_FILE"
ok "plugin JSON files are valid"

section "Manifest Consistency"
python3 - <<'PY'
import json
import os
from pathlib import Path

codex_mp = json.loads(Path(".agents/plugins/marketplace.json").read_text(encoding="utf-8"))
claude_mp = json.loads(Path(".claude-plugin/marketplace.json").read_text(encoding="utf-8"))


def norm(path: str) -> str:
    return os.path.normpath(path)


codex_entries = {}
for index, plugin in enumerate(codex_mp.get("plugins", [])):
    codex_entries[norm(plugin["source"]["path"])] = plugin.get("name")

claude_entries = {}
for index, plugin in enumerate(claude_mp.get("plugins", [])):
    claude_entries[norm(plugin["source"])] = plugin.get("name")

if set(codex_entries) != set(claude_entries):
    raise SystemExit(
        f"marketplace plugin sets differ: codex={sorted(codex_entries)} claude={sorted(claude_entries)}"
    )

for path in sorted(codex_entries):
    claude_manifest = json.loads(Path(path, ".claude-plugin", "plugin.json").read_text(encoding="utf-8"))
    codex_manifest = json.loads(Path(path, ".codex-plugin", "plugin.json").read_text(encoding="utf-8"))
    names = {
        "codex marketplace": codex_entries[path],
        "claude marketplace": claude_entries[path],
        ".claude-plugin/plugin.json": claude_manifest.get("name"),
        ".codex-plugin/plugin.json": codex_manifest.get("name"),
    }
    distinct = {value for value in names.values() if value is not None}
    if len(distinct) != 1:
        raise SystemExit(f"name mismatch for {path}: {names}")
    claude_version = claude_manifest.get("version")
    codex_version = codex_manifest.get("version")
    if claude_version != codex_version:
        raise SystemExit(
            f"version mismatch for {path}: .claude-plugin={claude_version} .codex-plugin={codex_version}"
        )
    print(f"OK {path}: name={distinct.pop()} version={claude_version}")
PY
ok "plugin names match across both manifests; versions agree across platforms"

section "Platform Validators"
while IFS= read -r plugin_dir; do
  if [[ "$RUN_CODEX" == "1" ]]; then
    python3 "$CODEX_PLUGIN_VALIDATOR" "$plugin_dir"
  fi
  claude plugin validate "$plugin_dir" --strict
done < "$PLUGIN_PATHS_FILE"
if [[ "$RUN_CODEX" == "1" ]]; then
  ok "Codex and Claude validators passed"
else
  ok "Claude validator passed (Codex skipped)"
fi

section "Release Residue Checks"
RELEASE_SCAN_TARGETS=(README.md .agents .claude-plugin plugins)
if grep -REn -- 'Internal beta|UNLICENSED|localhost|127\.0\.0\.1' "${RELEASE_SCAN_TARGETS[@]}"; then
  fail "release-blocking residue found"
fi
ok "no blocking residue found"

if grep -REn -- 'http://spider-mcp\.nb-sandbox\.com' "${RELEASE_SCAN_TARGETS[@]}" >/dev/null; then
  warn "sandbox HTTP MCP endpoint is still present; switch to stable HTTPS before public production release"
fi

section "MCP Smoke Tests"
if [[ "${SKIP_MCP:-0}" == "1" ]]; then
  warn "SKIP_MCP=1 set; skipping MCP smoke tests"
else
  while IFS= read -r plugin_dir; do
    endpoint="$(mcp_endpoint "$plugin_dir/.mcp.json")"
    found_smoke=0
    while IFS= read -r smoke_test; do
      found_smoke=1
      python3 "$smoke_test" --endpoint "$endpoint"
    done < <(find "$plugin_dir/skills" -path '*/scripts/smoke_test_mcp.py' -type f | sort)
    if [[ "$found_smoke" == "0" ]]; then
      warn "no smoke_test_mcp.py found under $plugin_dir/skills"
    fi
  done < "$PLUGIN_PATHS_FILE"
fi

section "Result"
ok "plugin release verification passed"
