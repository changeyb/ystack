# Porting pstack to another harness

This file inventories the places where the skill set assumes Cursor and the places where no portable fallback exists. It is written for the person or agent adapting these skills to another harness. For worked adapters, see [Claude Code](claude-code.md) and [Codex](codex.md).

Most Cursor references are adapter-level: a tool name, a path, a field, or a product feature. A harness adapter can translate the first kind without editing every skill. The items in Part C need a real implementation, a documented degraded mode, or an explicit skip.

Severity used below:

- **Map** — replace the name or path. Behavior is preserved.
- **Shim** — implement a small adapter layer in the harness.
- **Degrade** — a fallback exists but changes behavior. Say so in the reply.
- **Blocker** — the skill cannot run as written. Disable it, replace it, or skip its step with a note.

## Part B — Cursor-only usage

### B1. Delegation and subagents

All subagent work goes through Cursor's `Task` tool. The fields below appear across the skills. `Task` is also used as a verb in prose, so search for the field names, not only the tool name.

| Cursor usage | Meaning | Where it appears | Porting action |
| --- | --- | --- | --- |
| `Task` | Spawn a subagent. | [`poteto-mode`](../../skills/poteto-mode/SKILL.md), [`how`](../../skills/how/SKILL.md), [`why`](../../skills/why/SKILL.md), [`reflect`](../../skills/reflect/SKILL.md), [`swarm`](../../skills/swarm/SKILL.md), [`arena`](../../skills/arena/SKILL.md), [`interrogate`](../../skills/interrogate/SKILL.md), [`no-comments`](../../skills/no-comments/SKILL.md), [`multi-phase-plan`](../../skills/poteto-mode/playbooks/multi-phase-plan.md), [`orchestrate`](../../skills/poteto-mode/playbooks/orchestrate.md) | Map to the harness subagent tool: `Agent` in Claude Code, `task` in OpenCode, `spawn_agent` in Codex. |
| `subagent_type: generalPurpose` | General worker with the session's MCP servers. | [`how`](../../skills/how/SKILL.md), [`why`](../../skills/why/SKILL.md), [`reflect`](../../skills/reflect/SKILL.md), [`swarm`](../../skills/swarm/SKILL.md), [`interrogate`](../../skills/interrogate/SKILL.md) | Map to the harness's general-purpose agent. |
| `subagent_type: "poteto-agent"` | Cursor custom agent that carries the Poteto Mode style. | [`poteto-mode`](../../skills/poteto-mode/SKILL.md), [`multi-phase-plan`](../../skills/poteto-mode/playbooks/multi-phase-plan.md), [`poteto-help`](../../skills/poteto-help/SKILL.md) | Register an agent definition if the harness supports one. Otherwise spawn a general agent and prefix the brief with: "Read `<absolute path>/skills/poteto-mode/SKILL.md` in full, including its Principles section, before any work." |
| `subagent_type: "comment-sicko"` | Read-only comment reviewer. | [`no-comments`](../../skills/no-comments/SKILL.md) | Register it, or spawn a general agent with [`references/comment-sicko.md`](../../skills/no-comments/references/comment-sicko.md) as the prompt, followed by the scope. |
| `readonly: true` | Read-only agent mode. In Cursor this also strips MCP access. | [`how`](../../skills/how/SKILL.md), the Arena judge in [`arena`](../../skills/arena/SKILL.md), the default in [`poteto-mode`](../../skills/poteto-mode/SKILL.md) | Use the harness's read-only agent if it keeps MCP. If it strips MCP, use a general agent plus "do not edit files", then check `git status`. See C6. |
| `readonly: false` | Agent mode with MCP access. | [`why`](../../skills/why/SKILL.md), [`reflect`](../../skills/reflect/SKILL.md) | Use a general agent. Do not use a read-only mode that strips MCP. |
| `environment: "cloud"` | Run the subagent on a Cursor cloud VM. | [`swarm`](../../skills/swarm/SKILL.md), [`orchestrate`](../../skills/poteto-mode/playbooks/orchestrate.md), [`poteto-mode`](../../skills/poteto-mode/SKILL.md) | Map to a remote sandbox if the harness has one. Otherwise run locally in a worktree. This is a degraded mode; see C2. |
| `environment: "local"` | Run on the user's machine. | [`swarm`](../../skills/swarm/SKILL.md) | Omit, or use the harness default. |
| `cloud_base_branch` | Base branch for a cloud worker. | [`swarm`](../../skills/swarm/SKILL.md) | Tell the worker to check out that branch before work. |
| `run_in_background: true` | Do not block the parent turn. | [`arena`](../../skills/arena/SKILL.md), [`swarm`](../../skills/swarm/SKILL.md), [`poteto-mode`](../../skills/poteto-mode/SKILL.md) | Use the harness's background subagent mode, or let the native default apply. |
| `resume` | Continue an existing subagent. | [`poteto-mode`](../../skills/poteto-mode/SKILL.md) | Use the harness equivalent. If none, spawn a fresh agent with a consolidated brief: original task, later directives, and the prior report. |
| `file_attachments` | Attach files to a subagent. | [`poteto-mode`](../../skills/poteto-mode/SKILL.md) | List the paths in the brief. |
| `poteto-agent` and `comment-sicko` as agent names | Cursor-registered subagent types. | Same files as above. | These are the two custom agent definitions the skills assume. Treat them as part of the adapter contract. |

### B2. Questions and interaction

| Cursor usage | Meaning | Where it appears | Porting action |
| --- | --- | --- | --- |
| `AskQuestion` | Structured multiple-choice question. | [`poteto-mode`](../../skills/poteto-mode/SKILL.md), [`setup-pstack`](../../skills/setup-pstack/SKILL.md), [`automate-me`](../../skills/automate-me/SKILL.md), [`autonomous-run`](../../skills/poteto-mode/playbooks/autonomous-run.md) | `AskUserQuestion` in Claude Code, `question` in OpenCode, or numbered options in chat. |
| `allow_multiple: true` | Multi-select on a structured question. | [`automate-me`](../../skills/automate-me/SKILL.md) | Use the harness's multi-select option, or say "choose all that apply" in chat. |
| Custom Mode, Option+Enter / Alt+Enter, "Use as Mode" | Keep a skill in context across turns. | [`poteto-help`](../../skills/poteto-help/SKILL.md), [`01-setup`](../guide/01-setup.md), [`02-poteto-mode`](../guide/02-poteto-mode.md) | If the harness has no persistent mode, start each task with `/poteto-mode`. Do not invent a mode. |
| `/in-cloud` | Start a task in a cloud agent. | [`02-poteto-mode`](../guide/02-poteto-mode.md) | Map to the harness's remote-sandbox flag, or skip the feature. |

### B3. Models and reasoning effort

Cursor puts the model family, reasoning level, and speed in one slug, such as `claude-opus-5-5-xhigh` or `grok-4.7-xhigh-fast`. The skills treat the last token before an optional `fast` as the effort level.

| Cursor usage | Where it appears | Porting action |
| --- | --- | --- |
| Model slugs such as `claude-opus-5-5-xhigh`, `grok-4.7-xhigh-fast`, `composer-*` | [`setup-pstack`](../../skills/setup-pstack/SKILL.md), [`how`](../../skills/how/SKILL.md), [`why`](../../skills/why/SKILL.md), [`reflect`](../../skills/reflect/SKILL.md), [`swarm`](../../skills/swarm/SKILL.md), [`arena`](../../skills/arena/SKILL.md), [`architect`](../../skills/architect/SKILL.md), [`interrogate`](../../skills/interrogate/SKILL.md), [`poteto-mode`](../../skills/poteto-mode/SKILL.md) | Map each slug to a harness model ID plus an effort option. Keep `auto` and `inherit-parent` meaning "omit `model` and inherit the parent". |
| `pstack-models.mdc` with `alwaysApply: true` at `~/.cursor/rules/` | [`setup-pstack`](../../skills/setup-pstack/SKILL.md), [`poteto-help`](../../skills/poteto-help/SKILL.md), the model-reading skills | Cursor: `.mdc` with frontmatter. Claude Code: `~/.claude/rules/pstack-models.md`, no frontmatter. Other harnesses: `~/.agents/pstack-models.md`, read at task start. |
| Detecting available models from the `Task`/`Agent` tool schema | [`setup-pstack`](../../skills/setup-pstack/SKILL.md) | Expose a model catalog, or ask the user to paste valid IDs. Never write an unconfirmed ID. |
| Model families for cross-family review | [`arena`](../../skills/arena/SKILL.md), [`interrogate`](../../skills/interrogate/SKILL.md), [`reflect`](../../skills/reflect/SKILL.md), [`swarm`](../../skills/swarm/SKILL.md) | The harness must expose at least two model families. If it cannot, skip the cross-family judge and say so. See C5. |

### B4. Session state and transcripts

Several skills read the current workspace's transcripts to reconstruct context or verify a run. Cursor exposes an `agent-transcripts/` directory whose path the system prompt names.

| Cursor usage | Where it appears | Porting action |
| --- | --- | --- |
| `agent-transcripts/` directory | [`reflect`](../../skills/reflect/SKILL.md), [`recall`](../../skills/recall/SKILL.md), [`automate-me`](../../skills/automate-me/SKILL.md), [`show-me-your-work`](../../skills/show-me-your-work/SKILL.md), [`session-pickup`](../../skills/poteto-mode/playbooks/session-pickup.md), [`eval`](../../skills/poteto-mode/playbooks/eval.md), [`worktree-cleanup`](../../skills/poteto-mode/playbooks/worktree-cleanup.md) | Implement a transcript reader for the harness. The known paths are in the Harness section of [`poteto-mode`](../../skills/poteto-mode/SKILL.md). See C4. |
| "the root agent's store (path in the system prompt)" | [`autopilot-full`](../../skills/poteto-mode/playbooks/autopilot-full.md) | Supply an equivalent store path. If none exists, use `decisions.tsv` or `.audit/<task-slug>.tsv` and say where it lives. |
| Project tracker and Project store | [`orchestrate`](../../skills/poteto-mode/playbooks/orchestrate.md), [`07-overnight`](../guide/07-overnight.md) | Cursor Projects have no direct equivalent. Use `notes.md` in the repo for state. See C3. |

### B5. Repository and skill conventions

| Cursor usage | Where it appears | Porting action |
| --- | --- | --- |
| Project skill folder `.cursor/skills/`, user folder `~/.cursor/skills/` | [`poteto-mode`](../../skills/poteto-mode/SKILL.md), [`create-verification-skill`](../../skills/create-verification-skill/SKILL.md), [`automate-me`](../../skills/automate-me/SKILL.md), [`reflect`](../../skills/reflect/SKILL.md), [`setup-pstack`](../../skills/setup-pstack/SKILL.md) | Map to `.claude/skills/`, `.pi/skills/`, `.agents/skills/`, or the harness's own folder. |
| `.cursor/rules/*.mdc`, `alwaysApply` | [`setup-pstack`](../../skills/setup-pstack/SKILL.md), [`poteto-help`](../../skills/poteto-help/SKILL.md) | Map to `CLAUDE.md`, `AGENTS.md`, or the harness's always-on instruction file. The model rule is the exception: use the harness path. |
| `.cursor/plugins/`, `.cursor-plugin/plugin.json` | None of the skills depend on these after the plugin refactor. | Ignore. This skill set is installed by copy or symlink, not as a plugin. |
| `mcps/` directory exposed by Cursor | [`why`](../../skills/why/SKILL.md) | Use the harness's available-tools map. In Claude Code, MCP tools appear as `mcp__<server>__<tool>`. |
| `.cursor/worktrees/` | [`worktree-cleanup`](../../skills/poteto-mode/playbooks/worktree-cleanup.md) | Map to the harness's worktree root, or scan `git worktree list`. |
| `~/Library/Application Support/Cursor` cache cleanup | [`worktree-cleanup`](../../skills/poteto-mode/playbooks/worktree-cleanup.md) | Drop this item; it is Cursor-specific and optional. |
| `cursor.com/docs` links | [`01-setup`](../guide/01-setup.md), [`02-poteto-mode`](../guide/02-poteto-mode.md), [`05-build-and-clean`](../guide/05-build-and-clean.md), [`07-overnight`](../guide/07-overnight.md) | Keep as external references, or replace with the target harness's docs. They are not dependencies. |

### B6. Cursor product features

| Feature | What the skills assume | Where it appears | Porting action |
| --- | --- | --- | --- |
| Bugbot | An automated PR reviewer whose comments are ordinary review threads. | [`poteto-mode`](../../skills/poteto-mode/SKILL.md), [`bugbot-triage`](../../skills/poteto-mode/references/bugbot-triage.md), [`babysit`](../../skills/poteto-mode/playbooks/babysit.md), [`multi-phase-plan`](../../skills/poteto-mode/playbooks/multi-phase-plan.md) | Treat any bot review as a review thread. Skip Bugbot-specific pass counts when the forge has no Bugbot. |
| Automations | Routines, `update_state`, `SendToUser`, `api2.cursor.sh/automations/webhook`, routine wakes. | [`make-bot-ui`](../../skills/make-bot-ui/SKILL.md), [`07-overnight`](../guide/07-overnight.md) | No generic fallback. Replace with the harness's scheduler, webhook, and secret store, or disable the skill. See C1. |
| Cloud agents | A VM per worker, with its own branch and machine. | [`swarm`](../../skills/swarm/SKILL.md), [`orchestrate`](../../skills/poteto-mode/playbooks/orchestrate.md), [`shipping`](../../skills/poteto-mode/playbooks/shipping.md), [`autopilot-full`](../../skills/poteto-mode/playbooks/autopilot-full.md), [`autopilot-stack`](../../skills/poteto-mode/playbooks/autopilot-stack.md), [`multi-phase-plan`](../../skills/poteto-mode/playbooks/multi-phase-plan.md) | Map to a remote sandbox, or use local worktrees with serialization. See C2. |
| Projects | A persistent coordinator thread with a tracker and store, plus optional PR/CI event subscriptions. | [`orchestrate`](../../skills/poteto-mode/playbooks/orchestrate.md), [`07-overnight`](../guide/07-overnight.md) | Use `notes.md` for state. Event subscriptions need a harness equivalent; there is no polling fallback in that playbook. See C3. |
| Custom Modes | A skill kept in context every turn. | [`poteto-help`](../../skills/poteto-help/SKILL.md), [`01-setup`](../guide/01-setup.md), [`02-poteto-mode`](../guide/02-poteto-mode.md) | Re-invoke the skill each task, or use the harness's persistent mode if one exists. |
| `/visualize` | Cursor's charting command. | [`ketchup`](../../skills/ketchup/SKILL.md) | Use the harness's charting tool, a Mermaid diagram, or a generated chart. |
| `agent-transcripts/` | Session storage. | See B4. | Implement a reader. |

### B7. Built-in commands and tools

| Name | What it does | Where it appears | Porting action |
| --- | --- | --- | --- |
| `/loop` | Re-run a prompt on an event or heartbeat. | [`poteto-help`](../../skills/poteto-help/SKILL.md), [`autonomous-run`](../../skills/poteto-mode/playbooks/autonomous-run.md), [`babysit`](../../skills/poteto-mode/playbooks/babysit.md), [`shipping`](../../skills/poteto-mode/playbooks/shipping.md), [`autopilot-full`](../../skills/poteto-mode/playbooks/autopilot-full.md), [`multi-phase-plan`](../../skills/poteto-mode/playbooks/multi-phase-plan.md), [`07-overnight`](../guide/07-overnight.md) | Built into Cursor and Claude Code. Elsewhere, use a timed shell command or the harness's scheduler. |
| `/create-skill` | Cursor's skill-authoring flow. | [`poteto-mode`](../../skills/poteto-mode/SKILL.md), [`automate-me`](../../skills/automate-me/SKILL.md), [`reflect`](../../skills/reflect/SKILL.md), [`authoring-a-skill`](../../skills/poteto-mode/playbooks/authoring-a-skill.md) | Anthropic's `skill-creator`, or follow the Agent Skills format at agentskills.io. |
| `/in-cloud` | Start work in a cloud agent. | [`02-poteto-mode`](../guide/02-poteto-mode.md) | Map to the harness's remote-sandbox flag, or skip. |
| Todo list | Cursor's task list. | [`claude-code.md`](./claude-code.md) adapter note | Use `TodoWrite` when available, otherwise keep the list in the reply. |

`origin` (the forge CLI) is not a Cursor feature. It is an optional alternative to `gh` in the PR playbooks. See C9.

### B8. Search patterns for a port

Run these from the repository root to find every site that needs attention:

```bash
grep -rnE 'Task|subagent_type|generalPurpose|readonly|environment: "cloud"|cloud_base_branch|run_in_background|file_attachments' skills
grep -rnE 'AskQuestion|allow_multiple|Custom Mode|/in-cloud' skills docs
grep -rnE 'pstack-models|\.cursor/rules|alwaysApply|\.mdc' skills docs
grep -rnE 'agent-transcripts|~/.cursor/projects|Project store|Project tracker' skills docs
grep -rnE 'Bugbot|api2\.cursor\.sh|SendToUser|update_state|Automations' skills docs
grep -rnE '/loop|/create-skill|/visualize' skills docs
grep -rnE 'bun|deno|node |TLC|mise|pele|playwright|tmux|tailscale|simctl|xcrun' skills
```

The last command also finds runtime dependencies that are not Cursor-specific. See Part C.

### B9. Suggested adapter layers

Build the port in this order. Each layer is testable on its own.

1. **Paths.** Skill folders, model settings file, project/user install locations.
2. **Tools.** `Task` → subagent tool, `AskQuestion` → question tool, todo list.
3. **Agents.** `poteto-agent` and `comment-sicko`, plus the model and effort mapping.
4. **Session.** Transcript reader and the decision-trail store path.
5. **Features.** Bugbot, Automations, cloud agents, Projects, Custom Modes.
6. **Capabilities.** Forge CLI, Bun watcher, statechart runtime, browser/PTY control.
7. **Docs.** Replace or annotate the Cursor-specific links and install sections.

## Part C — No fallback, or a fallback that changes behavior

| # | Item | Severity | Fallback today |
| --- | --- | --- | --- |
| C1 | `make-bot-ui` and Cursor Automations | Blocker for Cursor parity | The [Codex relay](../../skills/poteto-mode/references/codex-events.md) submits a separate Cloud task from a button. |
| C2 | Cloud agents in the PR playbooks | Blocker for exact semantics; Degrade locally | Local worktree. Loses VM isolation and independent live verification. |
| C3 | Cursor Projects and event subscriptions | Blocker without event delivery | Codex can use a signed GitHub webhook for wakes and `notes.md` for program state. |
| C4 | Transcript access | Degrade or Blocker | Harness-specific reader. Some workflows lose their evidence source entirely. |
| C5 | Model diversity and per-subagent model | Degrade or Blocker for review panels | Omit `model`, or skip the cross-family judge. The diversity claim is lost. |
| C6 | `readonly` plus MCP | Degrade | General agent plus "do not edit", or a throwaway worktree. |
| C7 | Bun-based `watch-pr` | Blocker on the GitHub path | None. Port to Node or call `gh` directly. |
| C8 | `statechart` and TLA+ | Blocker for that skill | None for model checking. Mermaid text only after a successful run. |
| C9 | Forge CLI (`gh` or `origin`) | Blocker without either | None. Implement a forge adapter. |
| C10 | Browser/PTY control for live proof | Degrade or Blocker for verdicts | A project-provided driver, or skip the live lane. |
| C11 | `pstack` naming | Cosmetic | None needed, but rename everywhere or nowhere. |
| C12 | Test corpus absolute paths | Test-only | Regenerate the corpus in the new checkout. |

### C1. Cursor webhook routine and the Codex bot alternative

[`make-bot-ui`](../../skills/make-bot-ui/SKILL.md) has a [Codex Cloud relay](../../skills/poteto-mode/references/codex-events.md). The Cursor branch uses the following controls.

- `update_state` with target `routine` and action `create`.
- `SendToUser` with `type: secret-request` for the webhook sender key.
- A webhook URL at `https://api2.cursor.sh/automations/webhook/<id>`.
- The `[routine]` wake turn with a `<webhook_event>` block.
- Cursor's connector credential file for the secret.
- Tailscale for exposing the local page.

There is no generic equivalent for the routine, the secret request, or the wake payload. A harness that lacks all three cannot run this skill as written.

**Porting options:**

1. Implement the same shape on the target: a scheduled/event routine, a webhook URL, a secret store, and a wake event that carries the JSON body as untrusted data.
2. Disable the skill and remove its entry from the help table if the target has no such control plane.
3. Keep the security invariants if you rewrite it: the sender key stays server-side, never in chat or the browser; the POST body is untrusted; use one try with a short timeout; log failed posts locally.

The `07-overnight` automation paragraph has the same constraint. Its upstream pack is Cursor Automations-only and is not included in this repository.

### C2. Cloud agents in the PR playbooks — Blocker for exact semantics, Degrade with local worktrees

These skills assume a Cursor cloud agent, meaning a separate VM and branch per worker:

- [`shipping`](../../skills/poteto-mode/playbooks/shipping.md): one verifier per PR, each a cloud agent, running the app as a user.
- [`autopilot-full`](../../skills/poteto-mode/playbooks/autopilot-full.md): one owner per PR, each a cloud agent, plus swarm verifiers.
- [`autopilot-stack`](../../skills/poteto-mode/playbooks/autopilot-stack.md): the same without the merge.
- [`orchestrate`](../../skills/poteto-mode/playbooks/orchestrate.md): workers on a new cloud VM unless the work needs the local machine.
- [`swarm`](../../skills/swarm/SKILL.md): all workers in cloud by default.
- [`multi-phase-plan`](../../skills/poteto-mode/playbooks/multi-phase-plan.md): cloud workers for parallel phases.

The documented fallback is a local worktree. That preserves branch isolation but not machine isolation. It changes these assumptions:

- Ports, browsers, simulators, and build caches are shared.
- A crashed worker can leave processes behind.
- Two verifiers can fight over the same local app instance.
- The "assume the VM dies" recovery in `autopilot-full` has no VM to replace.

**Porting options:**

1. Map `environment: "cloud"` to a remote sandbox if the harness has one. This is the closest match.
2. Run locally with one owner per worktree and serialize anything that binds a port or launches the app. Add cleanup between owners.
3. Disable `shipping`, `autopilot-full`, and `autopilot-stack` if the harness cannot provide independent verification. Do not claim a `PASS` verdict from a lane that did not run the app.

### C3. Cursor Projects and event subscriptions — Blocker for `orchestrate`

[`orchestrate`](../../skills/poteto-mode/playbooks/orchestrate.md) keeps program state in a Project tracker/store and watches PRs with PR and CI event subscriptions. The playbook runs without polling.

A `notes.md` file in the repo holds program state. In Codex, the [signed event relay](../../skills/poteto-mode/references/codex-events.md) resumes a saved local coordinator on GitHub PR, review, and CI events. Without those subscriptions or another real event source, this playbook has no wake path.

**Porting options:**

1. Implement PR and CI event subscriptions in the harness adapter.
2. Relax the no-polling rule for this playbook and use the Babysit watcher on a heartbeat. Document the exception so it is not mistaken for the Cursor behavior.
3. Disable `orchestrate` and route standing programs to `autopilot-full` or `babysit` instead.

### C4. Transcript access — Degraded or Blocker depending on the workflow

These skills read the active workspace's transcripts:

- [`reflect`](../../skills/reflect/SKILL.md) mines a session for lessons.
- [`recall`](../../skills/recall/SKILL.md) rebuilds recent context across chats.
- [`automate-me`](../../skills/automate-me/SKILL.md) mines working habits.
- [`show-me-your-work`](../../skills/show-me-your-work/SKILL.md) audits the decision trail against what actually happened.
- [`session-pickup`](../../skills/poteto-mode/playbooks/session-pickup.md) resumes a prior run.
- [`eval`](../../skills/poteto-mode/playbooks/eval.md) verifies which files each candidate read.
- [`worktree-cleanup`](../../skills/poteto-mode/playbooks/worktree-cleanup.md) finds the newest chat that touched a worktree.

The Harness section of [`poteto-mode`](../../skills/poteto-mode/SKILL.md) describes the available sources. Codex uses scoped chat evidence through its [runtime adapter](../../skills/poteto-mode/references/codex.md#chat-evidence).

There is no universal transcript schema. A harness that exposes no session files cannot run these workflows as written.

**Porting options:**

1. Implement a transcript reader that returns a normalized event stream: role, text, tool name, tool input, tool output, timestamp, and file reads.
2. If the harness has no transcript access, mark `reflect`, `eval`, and `automate-me` as unavailable, and use `show-me-your-work`'s `decisions.tsv` as the audit source instead of the transcript.
3. Never glob across every project's session directory. Read only the active workspace.

### C5. Model diversity and per-subagent model selection — Degraded or Blocker for review panels

[`arena`](../../skills/arena/SKILL.md), [`interrogate`](../../skills/interrogate/SKILL.md), [`reflect`](../../skills/reflect/SKILL.md), [`swarm`](../../skills/swarm/SKILL.md), [`architect`](../../skills/architect/SKILL.md), [`how`](../../skills/how/SKILL.md), and [`why`](../../skills/why/SKILL.md) assign different models to different roles. Arena and Interrogate require a judge from a different model family than the parent.

If the harness has one model, or cannot set a model per subagent:

- The cross-family judge cannot run. Arena skips it and picks the base alone; say so.
- The review panels collapse to the parent model. The diversity claim in the reply is false unless you state the collapse.
- `setup-pstack` cannot detect models. Ask the user for valid IDs, or set every role to `auto`.

**Porting action:** expose a model catalog, a per-subagent model option, and an effort option. Map the slug's family and effort separately. Preserve `auto` and `inherit-parent` as "omit the model field".

### C6. `readonly` plus MCP — Degraded

Cursor's `readonly: true` strips MCP access. That is why [`why`](../../skills/why/SKILL.md) and [`reflect`](../../skills/reflect/SKILL.md) deliberately use `readonly: false`, and why [`how`](../../skills/how/SKILL.md) accepts losing MCP for its read-only explorers.

If the target harness's read-only agent also strips MCP, do not use it for `why` or `reflect`. Use a general agent, instruct it not to edit, and check `git status` afterward. If the harness cannot enforce read-only while keeping MCP, run the agent in a throwaway worktree.

### C7. The GitHub watcher requires Bun — Blocker on the GitHub path

[`babysit`](../../skills/poteto-mode/playbooks/babysit.md) and [`shipping`](../../skills/poteto-mode/playbooks/shipping.md) call `scripts/watch-pr/watch-pr`. That file starts with `#!/usr/bin/env bun`. On first run, `bootstrap.ts` runs `bun install --frozen-lockfile` to install `commander@14`, so it also needs the npm registry and network.

There is no Node fallback for `watch-pr`. The watcher is also GitHub-specific; the playbook says so and tells the agent not to pretend it covers Origin. It writes `node_modules/` and an install key next to itself, so a read-only skill install cannot bootstrap it either.

**Porting options:**

1. Install Bun and `gh` with authentication. This is the least work.
2. Port `cli.ts` and `github.ts` to Node. Keep the JSON verdict shape so the playbooks still parse it.
3. Call `gh pr view`, `gh pr checks`, and the review-thread API directly. You lose the state machine (`READY`, `WAITING`, `ADVANCE`, `COMPLETE`), so update the stop conditions in `babysit` and `shipping`.

### C8. `statechart` and TLA+ — Blocker for that skill

[`statechart`](../../skills/statechart/SKILL.md) and the TLA+ path in [`create-formal-verification-skill`](../../skills/create-formal-verification-skill/SKILL.md) need:

- A TypeScript-capable runtime: Node 22.18–22.x, Node 23.6+, Bun 1.1.5+, or Deno 2.0+.
- `mise` to install TLC 1.7.4 and Temurin Java 25 on first run.
- Network access on that first run.
- The npm package `pele@1.9.0` to render images. Without it, show the Mermaid text and the error.
- `TLA2TOOLS` to run the byte-exact corpus tests.

There is no portable model-checking fallback inside the skill. If the harness cannot provide Java, TLC, and `mise`, `/statechart` cannot run. The formal-verification skill can still use a different verifier, but the TLA+ route is unavailable.

The test corpus under `skills/statechart/scripts/test/corpus/` contains committed `.out` files with absolute paths such as `/agent/repos/plugins/pstack/...`. Byte-exact corpus tests will not match in another checkout unless you regenerate them with `STATECHART_UPDATE=1` and `TLA2TOOLS` set. This affects tests only, not the skill's runtime.

### C9. The forge: `gh` or `origin` — Blocker without either

[`babysit`](../../skills/poteto-mode/playbooks/babysit.md), [`shipping`](../../skills/poteto-mode/playbooks/shipping.md), [`autopilot-full`](../../skills/poteto-mode/playbooks/autopilot-full.md), [`autopilot-stack`](../../skills/poteto-mode/playbooks/autopilot-stack.md), [`opening-a-pr`](../../skills/poteto-mode/playbooks/opening-a-pr.md), and [`multi-phase-plan`](../../skills/poteto-mode/playbooks/multi-phase-plan.md) resolve a forge first. The default is `gh`; if `origin` exists and can resolve the repository, they use `origin pr`. Graphite is never required.

If neither command works, the PR playbooks cannot create, view, watch, or merge PRs. **Porting action:** implement a forge adapter with `view`, `checks`, `thread list`, `thread reply`, `create`, `edit`, `ready`, and `merge`. Keep the same result shape so the stop conditions still apply.

### C10. Control surfaces for live proof — Degraded or Blocker for verdicts

[`control-ui`](../../skills/control-ui/SKILL.md) needs an existing Playwright/Cypress harness, Playwright, or a Chromium debug port. [`control-cli`](../../skills/control-cli/SKILL.md) needs tmux, or a PTY script in Python, Node, or Expect. [`create-verification-skill`](../../skills/create-verification-skill/SKILL.md) chooses one of these to generate a project skill.

The PR playbooks require a live verifier: `shipping`, `autopilot-full`, and `autopilot-stack` post `PASS` only after the change runs as a user would. If the harness cannot drive a browser or a terminal, there is no live lane.

**Porting options:**

1. Provide the runtime: Playwright for UI, tmux or a PTY helper for CLI/TUI.
2. Use a named driver if the project already has one (`autopilot-full` allows this).
3. Do not produce a `PASS` verdict from a diff review alone. Mark the live lane skipped and say so.

`xcrun simctl` in [`worktree-cleanup`](../../skills/poteto-mode/playbooks/worktree-cleanup.md) is macOS/iOS-only and optional.

### C11. Naming is a contract — Cosmetic but easy to break

The set keeps the `pstack` name in file names and commands: `/setup-pstack`, `pstack-models.mdc` / `pstack-models.md`, `/poteto-mode`, `/poteto-help`, `poteto-agent`, and the `pstack` settings file. None of this is a runtime dependency, but the names are referenced across the skills and the docs.

If you rename the set, update every reference in the same change: skill frontmatter, cross-skill links, model-rule comments, help table, docs, and the install instructions. A partial rename leaves the model rule unreadable and the help links broken.

### C12. Optional and platform-specific dependencies

These do not block a port, but a harness should report them as unavailable rather than failing silently:

| Dependency | Used by | Handling |
| --- | --- | --- |
| MCP servers | [`why`](../../skills/why/SKILL.md), [`reflect`](../../skills/reflect/SKILL.md), [`automate-me`](../../skills/automate-me/SKILL.md) | Fewer evidence categories. Source control still works through git and `gh`. |
| Tailscale | [`make-bot-ui`](../../skills/make-bot-ui/SKILL.md) | Only for exposing the local page. Skip if the skill is disabled. |
| `pele@1.9.0` | [`statechart`](../../skills/statechart/SKILL.md) rendering | Fall back to the Mermaid text and show the error. |
| `xcrun simctl` | [`worktree-cleanup`](../../skills/poteto-mode/playbooks/worktree-cleanup.md) | macOS/iOS only. Skip elsewhere. |
| Video rendering | [`ketchup-video`](../../skills/ketchup-video/SKILL.md) | The skill already says: if the render fails, say so in one line and give only the calls. |
| A decision-trail store path | [`autopilot-full`](../../skills/poteto-mode/playbooks/autopilot-full.md), [`show-me-your-work`](../../skills/show-me-your-work/SKILL.md) | Use `decisions.tsv` or `.audit/<task-slug>.tsv` when the harness gives no store. |

### C13. Decide: map, shim, degrade, or disable

| Situation | Choice |
| --- | --- |
| Only the name differs | Map. No skill edit needed. |
| A small stable adapter preserves the semantics | Shim. Put it in the harness adapter, not in each skill. |
| The fallback loses isolation, model diversity, or live proof | Degrade. Say what was lost in the reply. |
| The feature has no equivalent and approximating it would be unsafe or misleading | Disable the skill or skip the step with one line. |
| A step needs a secret, a webhook, or a VM the harness cannot provide | Skip with: `Skipped in <harness>: <step>. <reason>.` Then continue. |

### C14. Minimum port checklist

1. Install the skill folders where the harness loads skills.
2. Write and read the harness-specific model settings file. Test `/setup-pstack`.
3. Map the subagent tool, `AskQuestion`, and the two custom agents.
4. Implement or disable the transcript reader.
5. Add the skip line for Cursor-only features.
6. Decide the cloud-agent strategy: remote sandbox, serialized local worktrees, or disable the PR playbooks.
7. Install the runtime the enabled skills need: `git`, `gh` or `origin`, Bun for `watch-pr`, and Node/Bun/Deno + Java/TLC for `statechart`.
8. Run a small task through `/poteto-mode`, then `/how`, `/why`, `/tdd`, `/no-comments`, and `/reflect`.
9. Grep for leftovers with the patterns in B8. Confirm that any remaining Cursor path is either intentional documentation or behind a skip.

## Related files

- [`claude-code.md`](./claude-code.md) — a worked adapter for Claude Code.
- [`docs/guide/README.md`](../guide/README.md) — the user-facing guide.
- [`skills/poteto-mode/SKILL.md`](../../skills/poteto-mode/SKILL.md) — the Harness section, which every skill reads.