
#!/usr/bin/env bats

# Load the Bash script
load ../action.sh

# Mock the curl command to simulate API responses
mock_curl() {
  local http_code=$1
  local response_file=$2
  echo "$http_code"
  cat "$response_file" > response_body.json
}

# Setup function to run before each test
setup() {
  export GITHUB_OUTPUT=$(mktemp)
}

# Teardown function to clean up after each test
teardown() {
  rm -f response_body.json "$GITHUB_OUTPUT" mock_response.json
}

@test "add_member_to_team succeeds with HTTP 200 for member role" {
  echo '{"role": "member", "state": "active"}' > mock_response.json
  curl() { mock_curl "200" mock_response.json; }
  export -f curl

  run add_member_to_team "test-user" "test-team" "member" "fake-token" "test-owner"

  [ "$status" -eq 0 ]
    [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=success" ]
}

@test "add_member_to_team succeeds with HTTP 200 for maintainer role" {
  echo '{"role": "maintainer", "state": "active"}' > mock_response.json
  curl() { mock_curl "200" mock_response.json; }
  export -f curl

  run add_member_to_team "test-user" "test-team" "maintainer" "fake-token" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=success" ]
}

@test "add_member_to_team fails with HTTP 404 (team or user not found)" {
  echo '{"message": "Not Found"}' > mock_response.json
  curl() { mock_curl "404" mock_response.json; }
  export -f curl

  run add_member_to_team "test-user" "test-team" "member" "fake-token" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Failed to add member to team test-team with role member. HTTP Status: 404" ]
}

@test "add_member_to_team fails with invalid role" {
  run add_member_to_team "test-user" "test-team" "invalid-role" "fake-token" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Invalid role 'invalid-role'. Must be 'member' or 'maintainer'." ]
}

@test "add_member_to_team fails with empty member_name" {
  run add_member_to_team "" "test-team" "member" "fake-token" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Missing required parameters: member-name, team-name, role, token, and owner must be provided." ]
}

@test "add_member_to_team fails with empty team_name" {
  run add_member_to_team "test-user" "" "member" "fake-token" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Missing required parameters: member-name, team-name, role, token, and owner must be provided." ]
}

@test "add_member_to_team fails with empty role" {
  run add_member_to_team "test-user" "test-team" "" "fake-token" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Missing required parameters: member-name, team-name, role, token, and owner must be provided." ]
}

@test "add_member_to_team fails with empty token" {
  run add_member_to_team "test-user" "test-team" "member" "" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Missing required parameters: member-name, team-name, role, token, and owner must be provided." ]
}

@test "add_member_to_team fails with empty owner" {
  run add_member_to_team "test-user" "test-team" "member" "fake-token" ""

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Missing required parameters: member-name, team-name, role, token, and owner must be provided." ]
}
