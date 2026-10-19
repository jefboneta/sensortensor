<!-- mcp-name: io.github.jefboneta/sensortensor -->
# sensortensor-mcp
## Install
pip install sensortensor-mcp
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

## License

MIT
<!-- mcp-name: io.github.jefboneta/sensortensor --> 
