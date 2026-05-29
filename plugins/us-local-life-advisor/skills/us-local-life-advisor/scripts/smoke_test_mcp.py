#!/usr/bin/env python3
"""Read-only smoke test for the US Local Data HTTP MCP endpoint."""

from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from typing import Any


DEFAULT_ENDPOINT = "http://spider-mcp.nb-sandbox.com/us-local-data/mcp"
REQUIRED_TOOLS = {"describe_sources", "resolve_local_geo", "query_local_data"}


def rpc(endpoint: str, method: str, params: dict[str, Any] | None = None, request_id: int = 1) -> dict[str, Any]:
    payload = {
        "jsonrpc": "2.0",
        "id": request_id,
        "method": method,
        "params": params or {},
    }
    request = urllib.request.Request(
        endpoint,
        data=json.dumps(payload).encode("utf-8"),
        method="POST",
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json, text/event-stream",
        },
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        body = response.read().decode("utf-8")
    data = json.loads(body)
    if "error" in data:
        raise RuntimeError(f"{method} failed: {data['error']}")
    return data


def tool_result(response: dict[str, Any]) -> dict[str, Any]:
    result = response.get("result", {})
    if result.get("isError"):
        raise RuntimeError(result.get("content", [{"text": "tool call failed"}])[0].get("text"))
    structured = result.get("structuredContent")
    if isinstance(structured, dict):
        return structured
    content = result.get("content") or []
    if content and isinstance(content[0], dict) and isinstance(content[0].get("text"), str):
        parsed = json.loads(content[0]["text"])
        if isinstance(parsed, dict):
            return parsed
    raise RuntimeError("tool response did not include structured JSON content")


def call_tool(endpoint: str, name: str, arguments: dict[str, Any], request_id: int) -> dict[str, Any]:
    response = rpc(
        endpoint,
        "tools/call",
        {"name": name, "arguments": arguments},
        request_id=request_id,
    )
    return tool_result(response)


def main() -> int:
    parser = argparse.ArgumentParser(description="Smoke test the US Local Data MCP endpoint.")
    parser.add_argument("--endpoint", default=DEFAULT_ENDPOINT, help="HTTP MCP endpoint URL")
    args = parser.parse_args()

    try:
        init = rpc(
            args.endpoint,
            "initialize",
            {
                "protocolVersion": "2025-03-26",
                "capabilities": {},
                "clientInfo": {"name": "us-local-life-advisor-smoke", "version": "0.1.0"},
            },
            request_id=1,
        )
        server_info = init.get("result", {}).get("serverInfo", {})
        print(f"OK endpoint: {args.endpoint}")
        print(f"OK server: {server_info.get('name', 'unknown')} {server_info.get('version', '')}".strip())

        tools_response = rpc(args.endpoint, "tools/list", request_id=2)
        tools = {
            tool.get("name")
            for tool in tools_response.get("result", {}).get("tools", [])
            if isinstance(tool, dict)
        }
        missing = sorted(REQUIRED_TOOLS - tools)
        if missing:
            raise RuntimeError(f"missing required tools: {', '.join(missing)}")
        print(f"OK tools: found {', '.join(sorted(REQUIRED_TOOLS))}")

        catalog = call_tool(
            args.endpoint,
            "describe_sources",
            {"source_ids": ["crime"], "include_examples": True},
            request_id=3,
        )
        if catalog.get("status") != "ok":
            raise RuntimeError(f"describe_sources status was {catalog.get('status')!r}")
        print("OK describe_sources: crime status ok")

        geo = call_tool(
            args.endpoint,
            "resolve_local_geo",
            {"location": {"scope": "city", "address": "San Jose, CA"}},
            request_id=4,
        )
        if geo.get("scope") != "city" or not geo.get("locations"):
            raise RuntimeError("resolve_local_geo did not return a usable city-level geo")
        print("OK resolve_local_geo: San Jose, CA city geo resolved")
    except (OSError, urllib.error.URLError, json.JSONDecodeError, RuntimeError) as exc:
        print(f"FAIL {exc}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
