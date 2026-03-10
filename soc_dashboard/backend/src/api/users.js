const express = require('express');
const router = express.Router();
router.get('/me', async (req, res) => {
  // Placeholder: fetch user role/permissions
  res.json({ user: { id: 'user-1', role: 'analyst', permissions: ['view', 'drilldown'] } });
});
module.exports = router;
