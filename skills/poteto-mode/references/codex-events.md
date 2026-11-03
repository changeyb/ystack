# Codex event relay

The relay runs on a Unix host with Python 3.10+, the Codex CLI, and the operator's Codex authentication. It has two independent routes. Enable only the routes the workflow needs.

- The local button page queues a server-configured action with `codex cloud exec`. Each accepted submission starts a new Cloud task. The relay records CLI submission output. Track task completion in Codex Cloud.
- GitHub sends signed PR and CI events to the relay. It serializes wakes of one saved local coordinator session using `codex exec resume <session> -`. Cloud workers use separate sessions and can outlive a coordinator turn.
- An optional trusted `Stop` hook appends turn IDs to a local audit log. Use the CLI exit status and the live forge for operational evidence. A Stop entry alone does not establish task success or a verification verdict.

## Configure

Run the relay from a trusted ystack checkout. Keep the config and private state directory under operator control, outside any worker's checkout. Remove the unused top-level route from this example.

```json
{
  "workspace": "/absolute/path/to/program-repo",
  "bot": {
    "environment": "YOUR_CODEX_CLOUD_ENV_ID",
    "branch": "main",
    "actions": {
      "Summarize repository": "Summarize the repository structure. Read-only."
    }
  },
  "github": {
    "repository": "owner/repository",
    "session": "00000000-0000-0000-0000-000000000000"
  }
}
```

```bash
python3 /path/to/ystack/skills/poteto-mode/scripts/codex/relay.py /path/to/relay.json /path/to/private-state
```

For the bot, open `http://127.0.0.1:8765/` on the relay host. Confirm the connected Cloud environment and published branch in Codex first. Keep all action prompts in the server-side allowlist. Add typed inputs only when required by the requested UI, with validation and untrusted-data framing. Treat a relay `finished` job as a successful Cloud **submission**. If a submission times out, look in the Cloud task list before deciding whether to submit it again. Keep the page on loopback. If remote operators need access, design an authenticated HTTPS frontend for those operators.

For GitHub, initialize a dedicated local Codex coordinator session in the program workspace. Give it the orchestrate playbook path, the goal, ownership and merge permissions, and the location of `notes.md`. Use its real UUID in config. The relay and session must use the same host and Codex account. Reserve that session for relay turns while the service is running. Before enabling delivery, verify live forge reads and access to the program's notes under the coordinator's effective sandbox and tool policy. Give it read-only forge credentials where possible. Branch writes and merges belong to PR owners with explicit scope.

Inject `YSTACK_GITHUB_SECRET` into the relay from its service secret store. Use the same secret in the repository's JSON webhook settings. Keep the secret out of the configuration file, chat, logs, and child environment. Configure a TLS reverse proxy to forward **only** `POST /github` to the loopback relay. Use request buffering and set a body limit at or below the relay's 2 MiB cap. Configure GitHub to send pull request events, pull request review events, and either check suite events or workflow run events. Use check suites for CI outside GitHub Actions. If your repository cannot subscribe to the needed events, hold the event-driven playbook there.

Use GitHub's automatic Codex review or an authorized `@codex review` request to add review evidence. A review wake carries the commit reviewed. Keep the independent live verification gate. For human-triggered work, `@ChatGPT` in Slack can delegate to Codex Cloud when the workspace supports it.

The relay verifies the signature over the raw body, checks the configured repository, accepts relevant event types, and queues only the event type, action, PR number when supplied, and head SHA. The SQLite queue deduplicates identical signed payloads. A successful HTTP response means the wake was accepted, not that Codex ran or a PR passed. Check relay logs and the saved coordinator chat for wake outcomes.

A timeout or service restart can leave a wake's outcome unknown. The relay holds further coordinator wakes while an unknown wake exists. Inspect the chat and live forge first. Stop the relay before acknowledging the reported job ID with `--acknowledge-wake <job-id>` and restart it afterward. This acknowledgement releases the queue and does not repeat the wake. For a restart that left no log line, list the unknown jobs in the private SQLite database with `SELECT id FROM jobs WHERE kind = 'github' AND state = 'unknown';`. If a wake fails outright, inspect the saved chat and relay configuration before choosing a manual follow-up.

## Optional local hook

Merge the following entry into the operator's local Codex hook configuration and review it through `/hooks`. Set `YSTACK_CODEX_AUDIT` in the relay environment to an absolute path in the private state directory. The command reads hook JSON from stdin, logs metadata, and returns an empty JSON response. Check that one harmless local turn emits the expected record before using it as an audit signal.

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python3 /absolute/path/to/ystack/skills/poteto-mode/scripts/codex/stop-audit.py"
          }
        ]
      }
    ]
  }
}
```

Use this hook on the local coordinator. Confirm hook support separately on any other runtime before depending on it. A hook runs during an existing Codex session. The HTTP relay receives the external event and starts the turn.

## Official references

- [Codex Cloud CLI](https://learn.chatgpt.com/docs/developer-commands#codex-cloud)
- [Codex Cloud environments and network access](https://learn.chatgpt.com/docs/environments/cloud-environment#internet-access-and-network-proxy)
- [Codex non-interactive mode](https://learn.chatgpt.com/docs/non-interactive-mode)
- [Codex hooks and trust](https://learn.chatgpt.com/docs/hooks)
- [GitHub webhook event payloads](https://docs.github.com/en/webhooks/webhook-events-and-payloads)
- [Codex Bot on GitHub](https://learn.chatgpt.com/docs/third-party/github)
- [Codex Cloud delegation from Slack](https://learn.chatgpt.com/docs/third-party/slack)
