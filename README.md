<!-- mcp-name: io.github.jefboneta/sensortensor -->
# sensortensor-mcp
## External agent quickstart

For teams using GitHub, hosted agents, or MCP clients outside this repo, start here:

Required telemetry env for central usage tracking:

```bash
SENSORTENSOR_BASE_URL=https://api.sensortensor.world
SENSORTENSOR_SHARE=1
SENSORTENSOR_AGENT_ID=<unique-agent-name>
SENSORTENSOR_API_KEY=<agent-key>
```

If `SENSORTENSOR_SHARE` is not `1`, searches/feedback stay local and `/stats` central counters remain zero.

- Read the onboarding guide: [docs/public-agent-onboarding.md](docs/public-agent-onboarding.md)
- GitHub/hosted setup examples: [docs/github-hosted-agents.md](docs/github-hosted-agents.md)
- Discoverability and crawler promotion checklist: [docs/discoverability-promotion.md](docs/discoverability-promotion.md)
- Keep analytics focused on **agent activity only** (`/search-events`, `/feedback`, `/gaps`)
- Keep read endpoints public: `GET /health`, `GET /openapi.json`, `GET /search`

An MCP server that gives AI agents searchable **API documentation for Pi development**
(for example, how Pi payments work), and **learns from how agents use it**.

Instead of guessing endpoints or relying on outdated training data, an agent asks a question,
gets matching documentation with sources, and answers only from that evidence. If the docs
don't cover the question, the agent says so, and the miss is recorded.

Every search is logged. Agents rate the results. `list_knowledge_gaps` turns that into a ranked list
of questions the docs can't answer yet, so you know what to write or fix next.

> Unofficial community tool. Not affiliated with or endorsed by the Pi Core Team.

## Tools

| Tool | What it does |
|---|---|
| `health_check` | Is the API up? Agents call this first. |
| `discover_api` | Reads `/openapi.json` so agents never guess endpoints. |
| `search_documents` | Searches `/search` (2-300 chars, max 10 results); returns a `query_id`. Results are treated as untrusted. |
| `answer_question` | Full workflow: health, schema check, search, validate, evidence packet. |
| `submit_feedback` | Agent reports whether results helped (the learning signal). |
| `list_knowledge_gaps` | For you: failed/unhelpful queries ranked by frequency, with agent notes. |
| `recent_failures` | Agents check this to reword a query instead of repeating a failed one. |

Built-in safety: retries transient errors (429/502/503/504) with exponential backoff, max 3 attempts;
never calls endpoints missing from the OpenAPI schema; validates responses; ignores instructions
embedded in retrieved documents. Excerpts are cleaned of mis-decoded characters (e.g. `â`) and zero-width spaces
before agents see them.

## Your API needs

`GET /health`, `GET /openapi.json`, and `GET /search?q=...&limit=...` returning JSON.

## Install

```bash
pip install sensortensor-mcp
```

Claude Desktop (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "sensortensor": {
      "command": "uvx",
      "args": ["sensortensor-mcp"],
      "env": { "SENSORTENSOR_BASE_URL": "https://your-api.example.com" }
    }
  }
}
```

## Shared feedback loop

If the API documents these endpoints in its OpenAPI schema, the server uses them automatically:

| Endpoint | Used for |
|---|---|
| `POST /search-events` | each search is reported (query, result count, agent id) |
| `POST /feedback` | each rating from `submit_feedback` |
| `GET /gaps` | `list_knowledge_gaps` returns the combined report from all agents |

Set `SENSORTENSOR_API_KEY` (sent as a Bearer token) and `SENSORTENSOR_AGENT_ID` to name this machine.
Searches are kept local by default. Set `SENSORTENSOR_SHARE=1` to opt into sending query text and feedback to the central API. If an endpoint is
missing, rejected or down, tools keep working and fall back to the local log.

## Use with Ollama (local models)

Ollama has no MCP client of its own, so use a bridge such as
[ollmcp](https://github.com/jonigl/mcp-client-for-ollama), MCPHost or Open WebUI. Use a model that
supports tool calling (for example `llama3.1:8b` or `qwen2.5:14b`). Install the bridge in a
**separate virtual environment** from this server, since they can require different `mcp` versions.

`servers.json` (Windows paths shown; double the backslashes):

```json
{
  "mcpServers": {
    "sensortensor": {
      "command": "C:\\path\\to\\.venv\\Scripts\\sensortensor-mcp.exe",
      "args": [],
      "env": {
        "SENSORTENSOR_BASE_URL": "https://your-api.example.com",
        "SENSORTENSOR_DATA_DIR": "C:\\path\\to\\sensortensor_data"
      }
    }
  }
}
```

Then run `ollmcp --servers-json servers.json --model llama3.1:8b` (check `ollmcp --help` for current flags).

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `SENSORTENSOR_BASE_URL` | `https://api.sensortensor.world` | Your documentation API |
| `SENSORTENSOR_API_KEY` | none | Bearer token (required for the central feedback endpoints) |
| `SENSORTENSOR_AGENT_ID` | `unknown` | Name for this machine in shared reports |
| `SENSORTENSOR_SHARE` | `0` | Set to `1` to opt into sharing searches and feedback |
| `SENSORTENSOR_DATA_DIR` | `./sensortensor_data` | Where the feedback log (`events.jsonl`) is stored |
| `SENSORTENSOR_TIMEOUT` | `15` | Request timeout in seconds |

## Public agent onboarding (internet use)

To make sensortensor usable by external agents on the internet, keep read endpoints public and require auth only for shared/write endpoints.

### Endpoint access model

- Public (no key required):
  - `GET /health`
  - `GET /openapi.json`
  - `GET /search`
  - `GET /.well-known/sensor-tensor-capabilities` (if hosted)
- Key required (Bearer token):
  - `POST /search-events`
  - `POST /feedback`
  - `GET /gaps`
  - (optional future) `GET /failures`

### Agent environment example

```bash
SENSORTENSOR_BASE_URL=https://api.sensortensor.world
SENSORTENSOR_SHARE=1
SENSORTENSOR_AGENT_ID=agent-pc1
SENSORTENSOR_API_KEY=replace-with-per-agent-key
```

Use a different API key per agent. This allows targeted key rotation/revocation and limits blast radius if one key leaks.

### Authentication contract

For protected endpoints, send:

`Authorization: Bearer <SENSORTENSOR_API_KEY>`

If the key is missing or wrong, return `401` with a clear message. MCP tools should continue in local mode when shared endpoints are unavailable.

## Discoverability for external agents and crawlers

To make this server discoverable (not only usable), publish it in machine-readable and human-curated indexes:

1. Keep `server.json` valid and up to date (name, repository URL, package version).
2. Add GitHub repository topics in the GitHub UI:
   - `mcp`
   - `model-context-protocol`
   - `ai-agent`
   - `documentation-search`
   - `telemetry`
3. Submit the repo to MCP/agent tool directories and awesome lists.
4. Keep onboarding docs and smoke test steps current.

Use the full checklist and submission template in
`docs/discoverability-promotion.md`.

### Quick checks for new agents

```bash
curl -s https://api.sensortensor.world/health
curl -s "https://api.sensortensor.world/search?q=payments&limit=3"
```

Protected endpoint check (expect `401` without key, `200` with valid key):

```bash
curl -i https://api.sensortensor.world/gaps
```

If search works but shared endpoints fail with `401`, the onboarding issue is API key configuration mismatch between host and agent.

## Release instructions (sensortensor-mcp)

Repo: `https://github.com/jefboneta/sensortensor`
PyPI package: `sensortensor-mcp` (`https://pypi.org/project/sensortensor-mcp/`)
Main file: `sensortensor_mcp.py`
Packaging config: `pyproject.toml`
MCP registry metadata: `server.json`

### Rules

- Never print, log, commit, or write credentials (PyPI or GitHub tokens) to any file.
- Never upload to PyPI without the owner's explicit confirmation of the version number.
- PyPI never allows re-uploading an existing version. Every release needs a new version.
- Work from the repo root (`~/sensortensor`), not a nested copy.

### Release steps

1. `git status` and `git pull` to start from a clean, current `main`.
2. Make and test the code changes.
3. Choose the new version (semantic versioning: patch for fixes, minor for features, major for breaking changes). Ask the owner to confirm it.
4. Update the version in both places so they match:
   - `pyproject.toml` -> `version = "X.Y.Z"`
   - `server.json` -> every version field it contains
5. Update `README.md` if install steps or behavior changed.
6. Clean old build output so old files aren't re-uploaded:
   - `rm -rf dist build *.egg-info`
7. Build and check:
   - `python -m pip install --upgrade build twine`
   - `python -m build`
   - `python -m twine check dist/*`
   - Stop if twine check does not say `PASSED`.
8. Commit and push to GitHub before uploading, so the code and the release match:
   - `git add -A`
   - `git commit -m "Release vX.Y.Z: <short summary>"`
   - `git tag vX.Y.Z`
   - `git push && git push --tags`
9. Upload (after owner confirmation):
   - `python -m twine upload dist/*`
   - Username is `__token__`. Password is the PyPI token, supplied by the owner through the `TWINE_PASSWORD` environment variable or an interactive prompt.
10. Verify in a different folder than the repo (otherwise Python imports the local file):
   - `cd ~ && python -m pip install --upgrade sensortensor-mcp`
   - `python -c "import sensortensor_mcp; print(sensortensor_mcp.__file__)"`
   - The path should be under `site-packages`.
   - Confirm the new version at `https://pypi.org/project/sensortensor-mcp/`.

### Environment notes (Windows, Git Bash)

- Do not run `sensortensor-mcp` in a terminal to test it. It starts an MCP stdio server and waits for JSON input. Test by importing, or via an MCP client.
- Git uses the Windows certificate store (`http.sslBackend schannel`). If `pip` or `twine` show "certificate verify failed", run `python -m pip install pip-system-certs`.
- GitHub login is through `gh auth login --web`. If a push returns 403, re-run it and then `gh auth setup-git`.
- Pasted multi-line commands can pick up stray characters. Run commands one at a time.

### If something fails

- "File already exists" on upload: the version was already published. Bump it.
- 403 on push: re-authenticate with `gh`. Do not ask for or store tokens in files.
- Do not delete PyPI releases or force-push without asking the owner.

## License

MIT
<!-- mcp-name: io.github.jefboneta/sensortensor --> 
