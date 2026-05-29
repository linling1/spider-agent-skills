# Platform Integration

US Local Life Advisor is distributed as agent instructions plus a hosted MCP data service.

In Claude Code, install via the repository marketplace so MCP is configured automatically. The repository root includes `.claude-plugin/marketplace.json`, and the plugin package lives at `plugins/us-local-life-advisor/` with its own `.claude-plugin/plugin.json`, `skills/`, and `.mcp.json` files.

```text
/plugin marketplace add <github-org>/spider-agent-skills
/plugin install us-local-life-advisor@spider-agent-skills
```

When installed this way, the `spider-us-local-data` MCP server is configured by the plugin and no manual MCP setup is required.

On other platforms, install the skill instructions via the skills CLI:

```bash
npx skills@latest add <github-org>/spider-agent-skills
```

This installs the agent skill instructions. It does not deploy the backend service and may not automatically configure MCP for every agent platform.

After installing the skill on a platform that does not auto-configure MCP, connect the agent platform to the US Local Data MCP endpoint:

```text
http://spider-mcp.nb-sandbox.com/us-local-data/mcp
```

Private distribution works if the user has access to the skills repository and their local GitHub authentication can clone it.

Platform notes:

- MCP-capable platforms should connect directly to the hosted MCP endpoint.
- Platforms with a plugin, connector, or marketplace model may wrap the same skill instructions and MCP configuration in a platform-specific package.
- Platforms without MCP support need a separate API or web integration layer.
- The hosted MCP service remains separate from the skills repository. Do not assume the user has backend source code or local service access.
