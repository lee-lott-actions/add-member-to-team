# Add Member to Team Action

This GitHub Action adds a GitHub user to a specified team in an organization with a given role using the GitHub API. It returns the result of the operation (`success` or `failure`) and an error message if the operation fails.

## Features
- Adds a user to a team in an organization via a PUT request to the GitHub API.
- Expects slugified usernames and team names for API compatibility.
- Supports `member` or `maintainer` roles for the team membership.
- Outputs the result of the operation (`result`) and an error message if applicable.
- Requires a GitHub token with organization admin permissions.
- Includes debug logging to ensure step output visibility in the GitHub Actions UI.

## Inputs
| Name          | Description                                              | Required | Default   |
|---------------|----------------------------------------------------------|----------|-----------|
| `member-name` | The slugified username of the member to add (e.g., "john-doe"). | Yes      | N/A       |
| `team-name`   | The slugified name of the team (e.g., "code-approvers"). | Yes      | N/A       |
| `role`        | The role to assign to the member ("member" or "maintainer"). | Yes      | `member`  |
| `token`       | GitHub token with organization admin permissions.        | Yes      | N/A       |
| `owner`       | The owner of the organization (user or organization).    | Yes      | N/A       |

## Outputs
| Name           | Description                                              |
|----------------|----------------------------------------------------------|
| `result`       | Result of the add member operation (`success` or `failure`). |
| `error-message`| Error message if the add member operation fails.         |

## Usage
1. **Add the Action to Your Workflow**:
   Create or update a workflow file (e.g., `.github/workflows/add-member-to-team.yml`) in your repository.

2. **Reference the Action**:
   Use the action by referencing the repository and version (e.g., `v1`).

3. **Example Workflow**:
   ```yaml
   name: Add Member to Team
   on:
     workflow_dispatch:
       inputs:
         member-name:
           description: 'Slugified username of the member to add (e.g., "john-doe")'
           required: true
         team-name:
           description: 'Slugified name of the team (e.g., "code-approvers")'
           required: true
         role:
           description: 'Role to assign ("member" or "maintainer")'
           default: 'member'
           required: true
   jobs:
     add-member:
       runs-on: ubuntu-latest
       steps:
         - name: Add Member to Team
           id: add-member
           uses: lee-lott-actions/add-member-to-team@v1.0.0
           with:
             member-name: ${{ github.event.inputs.member-name }}
             team-name: ${{ github.event.inputs.team-name }}
             role: ${{ github.event.inputs.role }}
             token: ${{ secrets.GITHUB_TOKEN }}
             owner: ${{ github.repository_owner }}
         - name: Print Result
           run: |
             if [[ "${{ steps.add-member.outputs.result }}" == "success" ]]; then
               echo "Successfully added ${{ github.event.inputs.member-name }} to team ${{ github.event.inputs.team-name }}."
             else
               echo "Error: ${{ steps.add-member.outputs.error-message }}"
               exit 1
             fi
