#!/bin/bash

add_member_to_team() {
  local member_name="$1"
  local team_name="$2"
  local role="$3"
  local token="$4"
  local owner="$5"

  if [ -z "$member_name" ] || [ -z "$team_name" ] || [ -z "$role" ] || [ -z "$token" ] || [ -z "$owner" ]; then
    echo "Error: Missing required parameters"
    echo "error-message=Missing required parameters: member-name, team-name, role, token, and owner must be provided." >> "$GITHUB_OUTPUT"
    echo "result=failure" >> "$GITHUB_OUTPUT"
    return
  fi

  # Convert role to lowercase for API compatibility
  role=$(echo "$role" | tr '[:upper:]' '[:lower:]')

  # Validate role
  if [ "$role" != "member" ] && [ "$role" != "maintainer" ]; then
    echo "Error: Invalid role '$role'. Must be 'member' or 'maintainer'."
    echo "error-message=Invalid role '$role'. Must be 'member' or 'maintainer'." >> "$GITHUB_OUTPUT"
    echo "result=failure" >> "$GITHUB_OUTPUT"
    return
  fi

  echo "Attempting to add member '$member_name' to team '$team_name' in organization '$owner' with role '$role'"

  # Use MOCK_API if set, otherwise default to GitHub API
  local api_base_url="${MOCK_API:-https://api.github.com}"

  # Add member to the team with specified role using GitHub API
  RESPONSE=$(curl -s -L \
    -w "%{http_code}" \
    -X PUT \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $token" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -H "Content-Type: application/json" \
    -o response_body.json \
    "$api_base_url/orgs/$owner/teams/$team_name/memberships/$member_name" \
    -d "{\"role\":\"$role\"}")

  if [ "$RESPONSE" -eq 200 ]; then
    echo "Successfully added $member_name to team $team_name with role $role"
    echo "result=success" >> "$GITHUB_OUTPUT"
  else
    echo "Error: Failed to add $member_name to team $team_name with role $role. HTTP Status: $RESPONSE"
    echo "error-message=Failed to add member to team $team_name with role $role. HTTP Status: $RESPONSE" >> "$GITHUB_OUTPUT"
    echo "result=failure" >> "$GITHUB_OUTPUT"
  fi

  # Clean up temporary file
  rm -f response_body.json
}
