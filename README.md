<!-- mcp-name: io.github.jefboneta/sensortensor -->
# sensortensor-mcp
for pi network development and the future of pi a agent development self inproving oracle system kind
An MCP server that lets agents search your API documentation, and **learns from how they use it**.

Every search is logged. Agents rate the results. `list_knowledge_gaps` turns that into a ranked list of
questions your docs can't answer yet, so you know what to write or fix next.

## Tools

| Tool | What it does |
|---|---|
| `health_check` | Is the API up? Agents call this first. |
| `discover_api` | Reads `/openapi.json` so agents never guess endpoints. |
| `search_documents` | Searches `/search`; returns a `query_id`. Results are treated as untrusted. |
| `answer_question` | Full workflow: health, schema check, search, validate, evidence packet. |
| `submit_feedback` | Agent reports whether results helped (the learning signal). |
| `list_knowledge_gaps` | For you: failed/unhelpful queries ranked by frequency, with agent notes. |
| `recent_failures` | Agents check this to reword a query instead of repeating a failed one. |

Built-in safety: retries transient errors (429/502/503/504) with exponential backoff, max 3 attempts;
never calls endpoints missing from the OpenAPI schema; validates responses; ignores instructions
embedded in retrieved documents.

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

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `SENSORTENSOR_BASE_URL` | `https://api.sensortensor.world` | Your documentation API |
| `SENSORTENSOR_API_KEY` | none | Optional Bearer token |
| `SENSORTENSOR_DATA_DIR` | `./sensortensor_data` | Where the feedback log (`events.jsonl`) is stored |
| `SENSORTENSOR_TIMEOUT` | `15` | Request timeout in seconds |

## License

MIT
