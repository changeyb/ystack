# 在 Codex 使用 ystack

在 ystack 的 Git 工作区根目录运行安装器。

```bash
./scripts/install-codex-skills.sh
```

要安装到另一个项目，传入该项目的 Git 工作区路径。

```bash
./scripts/install-codex-skills.sh /path/to/project
```

安装器在目标项目的 `.agents/skills/` 下创建指向 ystack 源码的软链。可重复执行，遇到同名技能目录或指向其他位置的链接时会停止并列出冲突。保留 ystack 源码目录，技能里的跨目录引用和脚本从这里解析。安装器按 [Codex 的技能发现规则](https://learn.chatgpt.com/docs/build-skills#where-codex-loads-local-skills) 布置软链。

在目标项目打开新的 Codex 对话，通过 `/skills` 查看技能，或直接调用 `$poteto-mode`、`$how`、`$why`、`$tdd`、`$no-comments` 和 `$reflect`。通过 `$setup-pstack` 配置角色模型。默认继承会话的子代理模型选择。原来只允许显式调用的技能通过 `agents/openai.yaml` 保留这个行为。

[运行时适配表](../../skills/poteto-mode/references/codex.md) 定义子代理、模型、聊天证据和各 playbook 的能力检查。

| 能力 | Codex 行为 |
| --- | --- |
| 子代理和模型 | 使用会话实际暴露的工具和模型。缺少可验证的跨家族模型时跳过相应裁判，并在结果中说明。 |
| 历史聊天 | 使用工作区范围可验证的聊天工具、当前对话或用户提供的记录。缺少历史时按技能约定降级。 |
| PR 盯跑 | 保留 `gh` 或 `origin` 判定。前台用现有 watcher 或 forge 检查。跨会话持续执行需要可用的调度能力和用户授权。 |
| PR 独立验证 | 可用独立 worktree，并串行使用共享的端口、浏览器和缓存。实际应用验证缺失时暂停对应的合并。 |
| 事件触发 | `make-bot-ui` 通过本地按钮提交 Cloud 任务。`orchestrate` 通过签名 GitHub 事件唤醒本地协调会话，并可派发 Cloud 工作。 |
| Bot 和 hooks | GitHub Codex Bot 提供评审，配置过的 Slack `@ChatGPT` 可以人工派发 Cloud 工作。可选的 `Stop` hook 记录本地 turn 元数据。 |

PR watcher 仍依赖 Bun 和已认证的 `gh`。浏览器、PTY 和 TLA+ 技能按各自的运行条件使用。完整依赖清单见 [Cursor 迁移清单](cursor-porting-notes.md)。

[事件中继配置](../../skills/poteto-mode/references/codex-events.md)包含 Cloud 环境、GitHub webhook、协调会话和 hook 的启用步骤。
