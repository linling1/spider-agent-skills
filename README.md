# Spider Agent Skills

Spider Agent Skills 是一个多 skills 仓库，用来分发 Spider 的 agent 能力说明。每个 skill 都是一个独立目录，包含 `SKILL.md` 和可选的 references、scripts、assets。

这个仓库只包含 agent instructions、plugin manifests 和平台接入说明，不包含后端服务、数据库、爬虫或数据处理代码。实际数据能力由托管服务提供。

## 安装

仓库地址：https://github.com/linling1/spider-agent-skills

### 作为 Codex/Claude Plugin 安装（推荐）

仓库根目录是 marketplace/catalog，真正的 plugin 包在 `plugins/us-local-life-advisor/`：

- Claude marketplace: `.claude-plugin/marketplace.json`
- Codex marketplace: `.agents/plugins/marketplace.json`
- Plugin root: `plugins/us-local-life-advisor/`
- Codex manifest: `plugins/us-local-life-advisor/.codex-plugin/plugin.json`
- Claude manifest: `plugins/us-local-life-advisor/.claude-plugin/plugin.json`
- Bundled skill: `plugins/us-local-life-advisor/skills/us-local-life-advisor/`
- Bundled MCP config: `plugins/us-local-life-advisor/.mcp.json`

Claude Code 可通过根目录 marketplace 安装：

```text
/plugin marketplace add linling1/spider-agent-skills
/plugin install us-local-life-advisor@spider-agent-skills
```

安装后 skill 会被自动发现，MCP server（`spider-us-local-data`）也由 plugin 自动配置并生效，无需手动添加。

### 在其它平台中使用

不支持 plugin marketplace 的 agent 平台，可以直接读取 `plugins/us-local-life-advisor/skills/us-local-life-advisor/` 中的 skill instructions。MCP 需要在对应 agent 平台上手动配置（见下文）。

仓库已公开，可直接 clone：`git clone https://github.com/linling1/spider-agent-skills.git`。

## 可用 Skills

### US Local Life Advisor

面向 agent 的美国本地生活决策能力。它连接托管的 US Local Data MCP 服务，让 agent 可以基于结构化本地数据回答安全、搬家、租房、买房、油价、交通、本地活动、招聘、房地产、本地预警、社区资源、安全停车、失踪人员、护理院等问题。

安装后，在你的 agent 平台中配置 MCP server：

```text
http://spider-mcp.nb-sandbox.com/us-local-data/mcp
```

然后让 agent 调用 `describe_sources(include_examples=true)` 验证连接和可用数据源。

## 上线前验证

每次迭代后、发布前，在仓库根目录运行：

```bash
./scripts/verify.sh
```

这个脚本会检查 Codex/Claude marketplace、plugin manifests、MCP 配置、平台 validator、发布残留关键词，并运行 MCP smoke test。

如果只想做离线结构检查，跳过网络 MCP smoke test：

```bash
SKIP_MCP=1 ./scripts/verify.sh
```

当前 MCP endpoint 仍是 sandbox HTTP 地址。脚本会给出 warning；正式公开生产发布前建议切换到稳定 HTTPS 域名。

## 仓库结构

```text
spider-agent-skills/
├── README.md
├── LICENSE
├── scripts/
│   └── verify.sh
├── .agents/
│   └── plugins/
│       └── marketplace.json
├── .claude-plugin/
│   └── marketplace.json
└── plugins/
│   └── us-local-life-advisor/
│       ├── .codex-plugin/
│       │   └── plugin.json
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── .mcp.json
│       └── skills/
│           └── us-local-life-advisor/
│               ├── SKILL.md
│               ├── references/
│               └── scripts/
```

约定：

- 根 `.claude-plugin/marketplace.json` 是 Claude Code marketplace 清单，`source` 指向 `./plugins/us-local-life-advisor`。
- 根 `.agents/plugins/marketplace.json` 是 Codex marketplace 清单，`path` 指向同一个 plugin 子目录。
- `plugins/<name>/` 是自包含 plugin 包；其内部的 `skills/` 和 `.mcp.json` 随安装一起复制。
- 项目使用 Apache-2.0 许可证发布；详见 `LICENSE`。

## 添加新 Skill

新增能力时，在 `plugins/` 下创建新的自包含 plugin 目录：

```text
plugins/<plugin-name>/
├── .codex-plugin/
│   └── plugin.json
├── .claude-plugin/
│   └── plugin.json
├── .mcp.json
└── skills/
    └── <skill-name>/
        ├── SKILL.md
        └── references/
```

然后同步更新根 `.claude-plugin/marketplace.json` 和 `.agents/plugins/marketplace.json`。
