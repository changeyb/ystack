# ystack

个人 Agent Skill 技能集。技能以 Markdown 编写，部分流程需要配套脚本和工具。

## 安装

Codex 项目安装运行 `./scripts/install-codex-skills.sh`，然后在该项目中调用 `$poteto-mode`。

其他 harness 可以把需要的技能目录复制或软链到对应的 skills 目录。

项目级：

| Harness | 目录 |
|---|---|
| Claude Code | `.claude/skills/` |
| Cursor | `.cursor/skills/` |
| Codex / OpenCode 等 | `.agents/skills/` |
| Pi | `.pi/skills/` |

用户级：`~/.claude/skills/`、`~/.cursor/skills/`、`~/.agents/skills/`、`~/.codex/skills/`、`~/.pi/agent/skills/`。

示例：

```bash
# 用户级安装 Claude Code
ln -s "$(pwd)/skills"/* ~/.claude/skills/

# 或只安装单个技能
ln -s "$(pwd)/skills/poteto-mode" ~/.claude/skills/poteto-mode
```

## 入口

| 技能 | 用途 |
|---|---|
| `/setup-pstack` | 配置每个角色使用的模型与推理预算 |
| `/poteto-mode` | 主入口：按任务选择 playbook 并执行 |
| `/poteto-help` | 查询该用哪个技能、playbook 或原则 |
| `/deslop` | 提交前清理 AI 生成的代码噪音 |
| `/control-cli` | 驱动和检查交互式 CLI / TUI |
| `/control-ui` | 驱动和检查 Web / IDE / Electron UI |

## 文档

- [`docs/guide/README.md`](docs/guide/README.md)：使用指南，从安装、`/poteto-mode` 路由到验证、过夜运行和定制，每页都有示例 prompt。
- [Codex 安装和能力边界](docs/harness/codex.md)。
- [`docs/harness/claude-code.md`](docs/harness/claude-code.md)：在 Claude Code 下把 Cursor 工具名、子代理字段和路径映射过去。
- [`docs/harness/cursor-porting-notes.md`](docs/harness/cursor-porting-notes.md)：Cursor 独有用法清单，以及没有通用 fallback、需要针对目标 harness 单独处理的点。

## 说明

- 技能正文以英文编写，面向 Agent 阅读；技能集内部沿用 pstack 命名（如 `/setup-pstack`、`pstack-models`）。
- Cursor 独有的工具名与路径，以及其他 harness 的对应写法，统一列在
  [`skills/poteto-mode/SKILL.md`](skills/poteto-mode/SKILL.md) 的 **Harness** 一节。
- `deslop`、`control-cli`、`control-ui` 改编自 Cursor Team Kit，MIT 许可，详见
  [`skills/ATTRIBUTION.md`](skills/ATTRIBUTION.md)。
