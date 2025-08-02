const express = require('express');
const app = express();
app.use(express.json());

app.put('/orgs/:owner/teams/:team_slug/memberships/:username', (req, res) => {
  console.log(`Mock intercepted: PUT /orgs/${req.params.owner}/teams/${req.params.team_slug}/memberships/${req.params.username}`);
  console.log('Request headers:', JSON.stringify(req.headers));
  console.log('Request body:', JSON.stringify(req.body));

  // Validate request body
  const { role } = req.body;
  if (!role) {
    return res.status(400).json({ message: 'Bad Request: Missing role in request body' });
  }

  // Validate role
  if (role !== 'member' && role !== 'maintainer') {
    return res.status(400).json({ message: `Bad Request: Invalid role '${role}'. Must be 'member' or 'maintainer'` });
  }

  // Simulate different responses based on username, team_slug, and owner
  if (req.params.owner === 'test-owner' && req.params.team_slug === 'test-team' && req.params.username === 'test-user') {
    res.status(200).json({ role, state: 'active' });
  } else if (req.params.username === 'existing-user') {
    res.status(403).json({ message: 'Forbidden: User already has a membership' });
  } else {
    res.status(404).json({ message: 'Not Found: Team or user does not exist' });
  }
});

app.listen(3000, () => {
  console.log('Mock server listening on http://127.0.0.1:3000...');
});
