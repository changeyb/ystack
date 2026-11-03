# Repository Guidelines

## Project Structure

ystack is a collection of agent skills. Each skill starts at `skills/<name>/SKILL.md`. Keep supporting references, scripts, and assets beside their owning skill. `skills/poteto-mode/playbooks/` contains the shared workflows. `docs/guide/` covers usage, `docs/harness/` covers installation and portability, and `scripts/` contains the Codex installer. Script tests and fixtures live with their tools.

## Development Commands

Run these commands from the repository root. Install dependencies inside the relevant script directory.

- `./scripts/install-codex-skills.sh /path/to/test-checkout` links the skills into a test Git checkout. Open it in Codex and invoke `$poteto-mode` to check discovery and routing.
- `(cd skills/poteto-mode/scripts && bun install --frozen-lockfile && bun run test && bun run typecheck)` runs the PR watcher and plan-check tests, then type-checks the watcher.
- `(cd skills/statechart/scripts && npm install --no-package-lock && npm test)` runs the Statechart suite with Node's test runner. Use Node 22.18+ on the 22.x line or Node 23.6+.
- `bash -n scripts/install-codex-skills.sh` checks installer syntax.

## Style and Compatibility

Write skill instructions in English. Use kebab-case skill directories and matching YAML `name` values. Keep harness-specific mappings in the relevant adapter and preserve explicit invocation settings in `agents/openai.yaml`. Match surrounding formatting, typically two spaces in TypeScript and four in Python. Keep each script's existing shell dialect and indentation.

## Testing

Name script tests `*.test.ts`. Use Bun's test API for Poteto tools and `node:test` for Statechart. Set `TLA2TOOLS` to the path to `tla2tools.jar` to include the TLC corpus cases. For skill changes, check relative links and exercise the affected invocation. Use a temporary checkout and mock external services for installer or relay smoke tests.

## Commits and Pull Requests

Follow the [PR playbook](skills/poteto-mode/playbooks/opening-a-pr.md) for new work. Use an imperative Conventional Commit title such as `fix(poteto-mode): handle stale review events`. Summarize the reason, scope, impact, and verification. Link the issue when applicable and attach screenshots or recordings when they demonstrate behavior.
