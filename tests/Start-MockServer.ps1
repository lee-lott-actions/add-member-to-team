param(
    [int]$Port = 3000
)

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()

Write-Host "Mock server listening on http://127.0.0.1:$Port..." -ForegroundColor Green

try {
    while ($listener.IsListening) {
        $context  = $listener.GetContext()
        $request  = $context.Request
        $response = $context.Response

        $path   = $request.Url.LocalPath
        $method = $request.HttpMethod

        Write-Host "Mock intercepted: $method $path" -ForegroundColor Cyan

        $statusCode = 200
        $responseJson = $null

        # HealthCheck endpoint: GET /HealthCheck
        if ($method -eq "GET" -and $path -eq "/HealthCheck") {
            $statusCode = 200
            $responseJson = @{ status = "ok" } | ConvertTo-Json
        }
        # PUT /orgs/:owner/teams/:team_slug/memberships/:username
        elseif ($method -eq "PUT" -and $path -match '^/orgs/([^/]+)/teams/([^/]+)/memberships/([^/]+)$') {
            $owner    = $Matches[1]
            $teamSlug = $Matches[2]
            $username = $Matches[3]

            Write-Host ("Mock intercepted: PUT /orgs/{0}/teams/{1}/memberships/{2}" -f $owner, $teamSlug, $username) -ForegroundColor Cyan
            Write-Host "Request headers: $($request.Headers | Out-String)"

            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $requestBody = $reader.ReadToEnd()
            $reader.Close()

            Write-Host "Request body: $requestBody"

            $bodyObj = $null
            try { $bodyObj = $requestBody | ConvertFrom-Json } catch { $bodyObj = $null }

            $role = $null
            if ($null -ne $bodyObj) { $role = $bodyObj.role }

            # Validate request body: role is required
            if ([string]::IsNullOrEmpty([string]$role)) {
                $statusCode = 400
                $responseJson = @{ message = "Bad Request: Missing role in request body" } | ConvertTo-Json -Compress
            }
            # Validate role
            elseif ($role -ne 'member' -and $role -ne 'maintainer') {
                $statusCode = 400
                $responseJson = @{ message = "Bad Request: Invalid role '$role'. Must be 'member' or 'maintainer'" } | ConvertTo-Json -Compress
            }
            else {
                # Simulate different responses
                if ($owner -eq 'test-owner' -and $teamSlug -eq 'test-team' -and $username -eq 'test-user') {
                    $statusCode = 200
                    $responseJson = @{ role = $role; state = 'active' } | ConvertTo-Json -Compress
                }
                elseif ($username -eq 'existing-user') {
                    $statusCode = 403
                    $responseJson = @{ message = 'Forbidden: User already has a membership' } | ConvertTo-Json -Compress
                }
                else {
                    $statusCode = 404
                    $responseJson = @{ message = 'Not Found: Team or user does not exist' } | ConvertTo-Json -Compress
                }
            }
        }
        else {
            $statusCode = 404
            $responseJson = @{ message = "Not Found" } | ConvertTo-Json -Compress
        }

        # Send response
        $response.StatusCode = $statusCode
        $response.ContentType = "application/json"

        $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseJson)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.Close()
    }
}
finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "Mock server stopped." -ForegroundColor Yellow
}