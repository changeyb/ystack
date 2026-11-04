# Codex runtime adapter

Read this before applying Cursor-specific steps in a ystack skill or playbook. Resolve skill links from the real path of the loaded `SKILL.md`, following symlinks. The project installer links the full skill set so sibling skills, references, and scripts are available. The mappings below take precedence over the Cursor examples in those files. Follow the current session's tool schemas, permissions, and user authorization.

## Invocation and tools

| In the skill | In Codex |
| --- | --- |
| `/skill-name`, Custom Mode, Use as Mode | Invoke with `$skill-name` or select from `/skills` where available. Start each new task with `$poteto-mode` when you want this workflow. If a routed skill is absent from the picker, read its local `SKILL.md` by path. |
| `Task`, `generalPurpose`, `run_in_background` | Use the session's native subagent spawn tool. For a schema with `task_name` and `message`, give each agent a unique valid name and put the full brief in `message`. Other Codex surfaces can expose different fields. Spawn eligible independent work, then collect reports through the available wait tool. Run read-only evidence lanes yourself if delegation is unavailable and label them as your own work. |
| `poteto-agent`, `comment-sicko` | Use a general agent. For Poteto, start the brief with the absolute path to `poteto-mode/SKILL.md` and ask it to read that file and this adapter before working. For the comment reviewer, use [the reviewer prompt](../../no-comments/references/comment-sicko.md) verbatim followed by the review scope. |
| `readonly`, MCP | Omit the Cursor flag. Instruct reviewers to avoid writes and check the diff or status afterward. This is a prompt constraint. Use a session-enforced read-only sandbox when that is required. Discover tools in the current session and report any inaccessible evidence lanes. |
| `resume`, `file_attachments` | Use the current session's agent message or follow-up tool for a stateful continuation. Otherwise spawn with the consolidated brief. Put file paths in the prompt. |
| `environment: "cloud"`, `cloud_base_branch` | Provide one prepared worktree per writing worker at the exact starting commit. Give the worker its absolute path and scope. Confirm worktree access and collect the diff from that path. Shared ports, browsers, and caches still need isolation or serialized use. See the playbook gates below. |
| `AskQuestion`, `allow_multiple` | Use a structured input tool only when exposed and permitted in the active mode. Otherwise ask in chat with numbered choices. For unsupported multi-select, let the user name all selected choices in chat. |
| Todo list, `Grep`, `Glob`, `/create-skill`, `/visualize` | Use the plan tool or a short checklist, `rg` and `rg --files`, `$skill-creator` if available, and an available visualization tool or Mermaid, respectively. |
| `.cursor/skills`, `.cursor/rules`, `alwaysApply` | Use `.agents/skills` for project skills, `~/.agents/skills` for personal skills, and the applicable `AGENTS.md` for repo instructions. The role settings below are read explicitly. |

## Models and setup

Use these defaults for Codex role selection, including when a playbook or standalone skill gives a Cursor model example. Terra handles scoped exploration, tooling review, and prose. Sol handles implementation, investigation, and synthesis. Astra handles the hardest tasks and the deeper design or review seat. Use the listed effort directly in Codex.

```text
feature, refactoring: gpt-6.1-sol high
bug-fix: gpt-6.1-sol medium
perf-issue: gpt-6.1-sol high
hillclimb: gpt-6.1-sol high
judgment and prose: gpt-6.1-terra medium
hardest tasks: gpt-6-astra xhigh
how explorer: gpt-6.1-terra medium
how explainer: gpt-6.1-sol medium
why investigators: gpt-6.1-sol medium
why synthesizer: gpt-6.1-sol high
reflect tooling: gpt-6.1-terra medium
reflect judgment, divergent, synthesizer: gpt-6-astra high
arena runners: gpt-6.1-sol high, gpt-6-astra high
arena cross-judge pool: gpt-6-astra high
swarm workers: gpt-6.1-sol medium
architect runners: gpt-6.1-sol high, gpt-6-astra xhigh
interrogate reviewers: gpt-6.1-sol high, gpt-6-astra high
```

- Resolve a named role from `~/.agents/pstack-models.md` first, then the table above. Values are `inherit-parent`, `auto`, or `<model-id> [<reasoning-effort>]`, with comma-separated entries for panels. Keep explicit aliases and omit both overrides for them. For a role without a settings key, use Terra medium for scoped read-only or prose work, Sol high for complex implementation, and Astra xhigh for the hardest work.
- Check IDs and efforts against the active subagent tool and session permissions. Model availability in the chat picker alone does not establish availability for a subagent. Pass the effort separately, for example as `reasoning_effort` when supported. If an override is unavailable or rejected, try the role default when it is supported and distinct. If the default cannot be used, omit the unsupported override and report the fallback. Session-wide defaults can differ from the parent's model. A full-history fork can restrict overrides, so follow the active tool contract.
- Preserve the number of runner or reviewer seats when a model falls back. GPT-6.1 Sol, GPT-6.1 Terra, and GPT-6 Astra are one family for pstack review gates. A cross-family judge requires a confirmed eligible family different from the parent. Skip the judge if the parent family or a different eligible family cannot be verified. Arena can still pick a base. Label same-family reviews in Interrogate, Reflect, and trail review. Hold Eval's cross-family verdict when its judge is unavailable.
- For `$setup-pstack`, show the effective choices from the table and existing settings. Budget selection is optional. Preserve the per-role efforts by default and apply a chosen budget only to confirmed models that support that effort. Confirm and validate overrides before writing them without Cursor frontmatter. A missing role line uses the table, so setup is optional. Preserve valid existing overrides unless the user changes them. If user-level writes are restricted, show the completed mapping and intended path. Continue with the setup skill's confirmation and optional verification steps.
- For Cloud dispatch, apply role defaults only when the dispatch surface exposes model and effort controls. Otherwise record the Cloud environment's effective settings when known.

## Chat evidence

Use the current conversation, an explicitly identified Codex chat through an available read-only chat tool, or a user-provided export. In the desktop app, use `list_threads` for project metadata and `read_thread` for selected chats when exposed. Establish the chat's workspace before reading its body. Limit the search to the requested workspace and time window. A matching title, a recent timestamp, or the existence of a local rollout file does not establish scope. Skip unrestricted scans of `~/.codex/sessions` and other harnesses' stores.

| Workflow | When scoped evidence is limited |
| --- | --- |
| Reflect | Use a digest of the current chat with evidence pointers. Record that transcript mining was skipped. |
| Recall | Use workspace-scoped chats when available. Otherwise use supplied chats, current context, and the skill's Git/forge sweep, and state the history coverage. |
| Automate me | Use the direct interview when workspace history is unavailable. Keep user-stated preferences distinct from observed patterns. |
| Show me your work | Check the decision log against available messages, command results, and artifacts. Mark missing transcript coverage. |
| Session pickup | Use the identified chat, handoff, or branch and reconstruct the resume point. Mark any decisions that cannot be recovered. |
| Eval | Require candidate tool events or equivalent file-read evidence for the chain check. Record missing observations as unverified. |
| Worktree cleanup | Run the audit with `--skip-transcripts` and verify active and pinned chat usage from a scoped Codex view or the user. Hold any worktree whose usage cannot be established. Skip Cursor cache cleanup. |

## Playbook gates

Apply these gates before spawning workers, arming a watcher, or advancing a merge. When a required capability is unavailable, name the skipped step and its reason. Continue with the work that has an independent completion condition.

- **Babysit.** Keep the forge and its stop conditions. In a live turn, use the watcher output and the terminal session's wait tool for GitHub, or the playbook's Origin checks. Use one watcher. If no background wake exists, a requested background run needs an authorized Codex heartbeat or falls back to a one-pass status check. Triage review threads as usual. Apply Bugbot-specific behavior only when its check or threads exist.
- **Autonomous run.** Use the available wait primitive for an active turn. If the user authorized a persistent run and the surface exposes scheduling, use a native automation or heartbeat with a concrete predicate, scope, and stop rule. In the desktop app, prefer an `automation_update` heartbeat attached to the current chat for recurring follow-ups. Stay quiet on unchanged checks unless the user requested updates. Record the schedule so it can be stopped on completion. A persistent schedule needs an actual scheduling tool.
- **Shipping, Autopilot-full, Autopilot-stack.** Replace the Cursor VM with an isolated worktree at the exact PR head only when independent verifiers can run the actual app. Serialize live lanes that share machine resources and stop leftover processes between lanes. Preserve the separation between PR owners and verifiers. Without independent live evidence, hold the verdict and merge at that frontier. For Autopilot-full's decision trail, use a workspace-local `.audit/<task-slug>.tsv` if no store exists. Keep the ownership and merge gates from the playbook. Use an authorized heartbeat for audit ticks when available, or audit in the active turn while owners are running.
- **Multi-phase plan.** Write the plan with real worktree, verifier, and wake capabilities. Identify any unavailable run step before the plan is used to start the program.
- **Orchestrate.** Use the [signed GitHub event relay](codex-events.md) and a saved local coordinator session. Keep the no-polling rule and stop if the needed PR and CI subscriptions are unavailable. Codex Cloud can run separate workers on published branches. Record task IDs, expected SHAs, and owners in `notes.md`.
- **Make bot UI.** Use the [button relay](codex-events.md) with an allowlisted Cloud action, or the configured Slack Bot for a human-triggered request. Hooks can audit local turns. Cloud submission and completion are separate states.

The forge CLI, Bun watcher, browser or PTY driver, and TLA+ runtime retain their own requirements. For app proof, drive the actual supported surface through an available browser or PTY tool. Record an unavailable live lane as skipped and withhold its verdict.
