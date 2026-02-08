function Add-MemberToTeam {
	param(
		[string]$MemberName,
		[string]$TeamName,
		[string]$Role,
		[string]$Token,
		[string]$Owner
	)

	# Validate required inputs
	if ([string]::IsNullOrEmpty($MemberName) -or
		[string]::IsNullOrEmpty($TeamName) -or
		[string]::IsNullOrEmpty($Role) -or
		[string]::IsNullOrEmpty($Token) -or
		[string]::IsNullOrEmpty($Owner)) {

		Write-Host "Error: Missing required parameters"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Missing required parameters: member-name, team-name, role, token, and owner must be provided."
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
		return
	}

	# Convert role to lowercase for API compatibility
	$Role = $Role.ToLowerInvariant()

	# Validate role
	if ($Role -ne "member" -and $Role -ne "maintainer") {
		$msg = "Invalid role '$Role'. Must be 'member' or 'maintainer'."
		Write-Host "Error: $msg"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$msg"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
		return
	}

	Write-Host "Attempting to add member '$MemberName' to team '$TeamName' in organization '$Owner' with role '$Role'"

	# Use MOCK_API if set, otherwise default to GitHub API
	$apiBaseUrl = $env:MOCK_API
	if (-not $apiBaseUrl) { $apiBaseUrl = "https://api.github.com" }

	$uri = "$apiBaseUrl/orgs/$Owner/teams/$TeamName/memberships/$MemberName"

	$headers = @{
		Authorization          = "Bearer $Token"
		Accept                 = "application/vnd.github+json"
		"Content-Type"         = "application/json"
		"User-Agent"           = "pwsh-action"
		"X-GitHub-Api-Version" = "2022-11-28"
	}

	$body = @{ role = $Role } | ConvertTo-Json -Compress

	try {
		$response = Invoke-WebRequest -Uri $uri -Method Put -Headers $headers -Body $body

		if ($response.StatusCode -eq 200) {
			Write-Host "Successfully added $MemberName to team $TeamName with role $Role."
			Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
		}
		else {
			$errorMsg = "Error: Failed to add $MemberName to team $TeamName with role $Role. HTTP Status: $($response.StatusCode)"
			Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
			Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"			
			Write-Host $errorMsg
		}
	}
	catch {
		$errorMsg = "Error: Failed to add $MemberName to team $TeamName with role $Role. Exception: $($_.Exception.Message)"		
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
		Write-Host $errorMsg
	}
}