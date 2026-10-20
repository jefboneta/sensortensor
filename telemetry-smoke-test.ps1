param(
	[string]$BaseUrl = $(if ($env:SENSORTENSOR_BASE_URL) { $env:SENSORTENSOR_BASE_URL } else { "https://api.sensortensor.world" }),
	[string]$ApiKey = $env:SENSORTENSOR_API_KEY,
	[string]$AgentId = $(if ($env:SENSORTENSOR_AGENT_ID) { $env:SENSORTENSOR_AGENT_ID } else { "admin-smoke" }),
	[string]$Query = "telemetry smoke test"
)

$BaseUrl = $BaseUrl.TrimEnd('/')

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
	Write-Host "SENSORTENSOR_API_KEY is missing. Set it first, then rerun."
	exit 1
}

$headers = @{ Authorization = "Bearer $ApiKey" }
$queryId = "diag-" + ([guid]::NewGuid().ToString("N").Substring(0, 12))

$searchBody = @{
	query_id = $queryId
	query = $Query
	agent_id = $AgentId
	n_results = 1
} | ConvertTo-Json

$feedbackBody = @{
	query_id = $queryId
	query = $Query
	helpful = $true
	note = "smoke test"
	agent_id = $AgentId
	n_results = 1
} | ConvertTo-Json

Write-Host "Posting /search-events with query_id=$queryId"
$searchResp = Invoke-RestMethod -Uri "$BaseUrl/search-events" -Method Post -Headers $headers -ContentType "application/json" -Body $searchBody
$searchResp | Format-List

Write-Host ""
Write-Host "Posting /feedback with query_id=$queryId"
$feedbackResp = Invoke-RestMethod -Uri "$BaseUrl/feedback" -Method Post -Headers $headers -ContentType "application/json" -Body $feedbackBody
$feedbackResp | Format-List

Write-Host ""
Write-Host "Done. Run .\network-activity-insights.ps1 to verify /stats increased."
