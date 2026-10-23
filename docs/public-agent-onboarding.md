# Public agent onboarding

Use this guide when external agents (GitHub users, cloud hosts, MCP clients on other machines) need access to SensorTensor.

## Goal

Provide searchable documentation to agents and capture **agent activity only** as feedback signals.

Public documentation search does not require an API key or telemetry sharing.
Central reporting is opt-in. Set `SENSORTENSOR_SHARE=1` only when the agent
operator agrees to share search queries and submitted feedback with the API.

## 1) API access model

### Public read endpoints

Keep these open so any agent can discover and query docs:

- `GET /health`
- `GET /openapi.json`
- `GET /search?q=...&limit=...`

### Protected shared endpoints

Require `Authorization: Bearer <SENSORTENSOR_API_KEY>` for:

- `POST /search-events`
- `POST /feedback`
- `GET /gaps`

## 2) Minimum MCP server config

```json
{
  "mcpServers": {
	"sensortensor": {
	  "command": "uvx",
	  "args": ["sensortensor-mcp"],
	  "env": {
		"SENSORTENSOR_BASE_URL": "https://api.sensortensor.world",
		"SENSORTENSOR_SHARE": "1",
		"SENSORTENSOR_AGENT_ID": "agent-pc1",
		"SENSORTENSOR_API_KEY": "replace-with-agent-key"
	  }
	}
  }
}
```

Notes:

- Keep one API key per agent identity (`SENSORTENSOR_AGENT_ID`).
- For search-only use, omit `SENSORTENSOR_SHARE` and `SENSORTENSOR_API_KEY`.
- Never use a real API key in committed examples or configuration files.
- If shared endpoints fail, tools still work in local mode.

## 3) Validation checklist

Run these from any machine (no auth required):

```bash
curl -s https://api.sensortensor.world/health
curl -s "https://api.sensortensor.world/search?q=payments&limit=3"
```

Protected endpoint check:

```bash
curl -i https://api.sensortensor.world/gaps
```

Expected:

- `401` without key
- `200` with a valid key

Optional central telemetry smoke test (PowerShell, with valid key):

```powershell
.\telemetry-smoke-test.ps1
.\network-activity-insights.ps1
```

## 4) Operational guidance

- Rotate keys per agent, not per team.
- Do not log or commit API keys.
- Review `/gaps` regularly to prioritize missing documentation.
- Keep telemetry scoped to agent workflows (queries, results, feedback), not human behavior.

## 5) Common onboarding issues

- `401` on shared endpoints: wrong/missing `SENSORTENSOR_API_KEY`.
- Search works but no central insights: `SENSORTENSOR_SHARE` is not `1`.
- Tools unavailable in client: MCP server not registered in that client profile.
