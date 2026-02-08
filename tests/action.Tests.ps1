BeforeAll {
	$script:MemberName = "test-user"
	$script:TeamName   = "test-team"
	$script:Owner      = "test-owner"
	$script:Token      = "fake-token"

	. "$PSScriptRoot/../action.ps1"
}

Describe "Add-MemberToTeam" {
	BeforeEach {
		$env:GITHUB_OUTPUT = [System.IO.Path]::GetTempFileName()
	}

	AfterEach {
		if (Test-Path $env:GITHUB_OUTPUT) {
			Remove-Item $env:GITHUB_OUTPUT -Force
		}
	}

	It "add_member_to_team succeeds with HTTP 200 for member role" {
		Mock Invoke-WebRequest {
			[PSCustomObject]@{
				StatusCode = 200
				Content    = '{"role":"member","state":"active"}'
			}
		}

		Add-MemberToTeam -MemberName $MemberName -TeamName $TeamName -Role "member" -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=success"
	}

	It "add_member_to_team succeeds with HTTP 200 for maintainer role" {
		Mock Invoke-WebRequest {
			[PSCustomObject]@{
				StatusCode = 200
				Content    = '{"role":"maintainer","state":"active"}'
			}
		}

		Add-MemberToTeam -MemberName $MemberName -TeamName $TeamName -Role "maintainer" -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=success"
	}

	It "add_member_to_team fails with HTTP 404 (team or user not found)" {
		Mock Invoke-WebRequest {
			[PSCustomObject]@{
				StatusCode = 404
				Content    = '{"message":"Not Found"}'
			}
		}

		Add-MemberToTeam -MemberName $MemberName -TeamName $TeamName -Role "member" -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		($output | Where-Object { $_ -match "^error-message=Error: Failed to add $MemberName to team $TeamName with role member. HTTP Status: 404" }) |
			Should -Not -BeNullOrEmpty
	}

	It "add_member_to_team fails with invalid role" {
		Add-MemberToTeam -MemberName $MemberName -TeamName $TeamName -Role "invalid-role" -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Invalid role 'invalid-role'. Must be 'member' or 'maintainer'."
	}

	It "add_member_to_team fails with empty member_name" {
		Add-MemberToTeam -MemberName "" -TeamName $TeamName -Role "member" -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Missing required parameters: member-name, team-name, role, token, and owner must be provided."
	}

	It "add_member_to_team fails with empty team_name" {
		Add-MemberToTeam -MemberName $MemberName -TeamName "" -Role "member" -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Missing required parameters: member-name, team-name, role, token, and owner must be provided."
	}

	It "add_member_to_team fails with empty role" {
		Add-MemberToTeam -MemberName $MemberName -TeamName $TeamName -Role "" -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Missing required parameters: member-name, team-name, role, token, and owner must be provided."
	}

	It "add_member_to_team fails with empty token" {
		Add-MemberToTeam -MemberName $MemberName -TeamName $TeamName -Role "member" -Token "" -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Missing required parameters: member-name, team-name, role, token, and owner must be provided."
	}

	It "add_member_to_team fails with empty owner" {
		Add-MemberToTeam -MemberName $MemberName -TeamName $TeamName -Role "member" -Token $Token -Owner ""

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Missing required parameters: member-name, team-name, role, token, and owner must be provided."
	}

	It "writes result=failure and error-message on exception (catch block)" {
		Mock Invoke-WebRequest { throw "API Error" }

		Add-MemberToTeam -MemberName $MemberName -TeamName $TeamName -Role "member" -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		($output | Where-Object { $_ -match "^error-message=Error: Failed to add $MemberName to team $TeamName with role member\. Exception:" }) |
			Should -Not -BeNullOrEmpty
	}
}