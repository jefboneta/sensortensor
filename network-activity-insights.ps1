param(
	[string]$BaseUrl = $(if ($env:SENSORTENSOR_BASE_URL) { $env:SENSORTENSOR_BASE_URL } else { "https://api.sensortensor.world" }),
	[string]$ApiKey = $env:SENSORTENSOR_API_KEY,
	[int]$GapLimit = 10
)

$BaseUrl = $BaseUrl.TrimEnd('/')

function Invoke-SensorTensorGet {
	param(
		[string]$Url,
		[string]$Bearer
	)

	$headers = @{}
	if (-not [string]::IsNullOrWhiteSpace($Bearer)) {
		$headers["Authorization"] = "Bearer $Bearer"
	}

	try {
		return @{ Ok = $true; Data = (Invoke-RestMethod -Uri $Url -Method Get -Headers $headers); Error = $null }
	}
	catch {
		$status = $null
		if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
			$status = [int]$_.Exception.Response.StatusCode
		}
		return @{ Ok = $false; Data = $null; Error = "HTTP $status - $($_.Exception.Message)" }
	}
}

Write-Host "SensorTensor network activity insights"
Write-Host "Current directory: $(Get-Location)"
Write-Host "Script path: $PSCommandPath"
Write-Host "Base URL: $BaseUrl"
Write-Host "Generated: $((Get-Date).ToUniversalTime().ToString('u'))"
Write-Host ""

$health = Invoke-SensorTensorGet -Url "$BaseUrl/health" -Bearer $ApiKey
if (-not $health.Ok) {
	Write-Host "Health check failed: $($health.Error)"
	exit 1
}

$stats = Invoke-SensorTensorGet -Url "$BaseUrl/stats" -Bearer $ApiKey
if (-not $stats.Ok) {
	Write-Host "Stats check failed: $($stats.Error)"
	exit 1
}

$gaps = Invoke-SensorTensorGet -Url "$BaseUrl/gaps?limit=$GapLimit" -Bearer $ApiKey
if (-not $gaps.Ok) {
	Write-Host "Gaps check failed: $($gaps.Error)"
	Write-Host "Tip: /gaps may require a valid API key."
	exit 1
}

$centralSearches = [int]$stats.Data.central_searches
$feedbackRecords = [int]$stats.Data.feedback_records
$unhelpfulFeedback = [int]$stats.Data.unhelpful_feedback
$docsIndexed = [int]$stats.Data.documents_indexed

$helpfulFeedback = [Math]::Max(0, $feedbackRecords - $unhelpfulFeedback)
$feedbackRate = if ($centralSearches -gt 0) { [Math]::Round(($feedbackRecords / $centralSearches) * 100, 1) } else { 0 }
$unhelpfulRate = if ($feedbackRecords -gt 0) { [Math]::Round(($unhelpfulFeedback / $feedbackRecords) * 100, 1) } else { 0 }

Write-Host "=== Network totals ==="
Write-Host "Documents indexed : $docsIndexed"
Write-Host "Central searches  : $centralSearches"
Write-Host "Feedback records  : $feedbackRecords"
Write-Host "Helpful feedback  : $helpfulFeedback"
Write-Host "Unhelpful feedback: $unhelpfulFeedback"
Write-Host "Feedback/search % : $feedbackRate"
Write-Host "Unhelpful/feedback%: $unhelpfulRate"
Write-Host ""

$gapItems = @()
if ($gaps.Data -and $gaps.Data.gaps) {
	$gapItems = @($gaps.Data.gaps)
}

Write-Host "=== Top documentation gaps ==="
if ($gapItems.Count -eq 0) {
	Write-Host "No gaps reported yet."
}
else {
	$gapItems |
		Select-Object -First $GapLimit query, count, empty, unhelpful |
		Format-Table -AutoSize
}
Write-Host ""

Write-Host "=== Diagnosis ==="
if ($centralSearches -eq 0) {
	Write-Host "No network usage detected. Most likely causes:"
	Write-Host "- External agents are not pointed to this API base URL"
	Write-Host "- SENSORTENSOR_SHARE is not set to 1 on clients"
	Write-Host "- Clients can search locally but are not sending /search-events"
	Write-Host "- Onboarding/discovery is weak (agents do not know this service exists)"
}
elseif ($feedbackRecords -eq 0) {
	Write-Host "Agents are searching but not sending feedback."
	Write-Host "Action: enforce submit_feedback after answers in client workflows."
}
elseif ($unhelpfulRate -ge 50) {
	Write-Host "High unhelpful ratio. Docs may not answer the top agent intents."
	Write-Host "Action: prioritize top gaps and improve those docs first."
}
else {
	Write-Host "Usage exists and quality signal is mixed/healthy."
	Write-Host "Action: keep monitoring gaps and feedback rate trend over time."
}

Write-Host ""
Write-Host "=== Next actions to learn why creators stop ==="
Write-Host "1) Track weekly returning agent_id count in central storage"
Write-Host "2) Log first-seen and last-seen per agent_id"
Write-Host "3) Compare drop-off cohorts against top unhelpful queries"
Write-Host "4) Add short onboarding checklist for external creators"