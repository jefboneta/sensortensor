# Discoverability and promotion checklist

Use this checklist when promoting the GitHub user version so external agents and crawlers can find SensorTensor.

## 1) Repository metadata (GitHub UI)

Set repository topics:

- `mcp`
- `model-context-protocol`
- `ai-agent`
- `documentation-search`
- `telemetry`

Optional additions:

- `python`
- `developer-tools`
- `api`

## 2) Machine-readable metadata

- Keep `server.json` in repo root.
- Ensure `server.json` fields are accurate:
  - `name`
  - `description`
  - `version`
  - `repository.url`
  - package `identifier` and `version`
- Keep API read endpoints reachable:
  - `GET /health`
  - `GET /openapi.json`
  - `GET /search`

## 3) External agent onboarding quality

- Keep this block copy/paste-ready in docs:

```bash
SENSORTENSOR_BASE_URL=https://api.sensortensor.world
SENSORTENSOR_SHARE=1
SENSORTENSOR_AGENT_ID=<unique-agent-name>
SENSORTENSOR_API_KEY=<agent-key>
```

- Keep smoke test documented:

```powershell
.\telemetry-smoke-test.ps1
.\network-activity-insights.ps1
```

## 4) Directory/list submissions

Submit to:

- MCP server directories/catalogs
- "Awesome MCP" lists
- Agent tool registries where MCP tools are indexed

When submitting, include:

- repo URL
- short description
- install command (`uvx sensortensor-mcp`)
- required env vars for telemetry
- verification commands

## 5) Submission template

Title:

`SensorTensor MCP: searchable docs + shared telemetry loop`

Body:

```text
SensorTensor is an MCP server for searchable API documentation with an optional shared telemetry loop.

Repo: https://github.com/jefboneta/sensortensor
Install: uvx sensortensor-mcp

Public endpoints:
- GET /health
- GET /openapi.json
- GET /search

Shared endpoints (auth):
- POST /search-events
- POST /feedback
- GET /gaps

Telemetry env:
- SENSORTENSOR_BASE_URL
- SENSORTENSOR_SHARE=1
- SENSORTENSOR_AGENT_ID
- SENSORTENSOR_API_KEY
```

## 6) Verification after promotion

- New users can discover and install from listing.
- `health_check` and `search_documents` work in external hosts.
- Central `/stats` shows growth in searches/feedback over time.
- Distinct `agent_id` values appear from external adopters.
