const express = require('express');
const router = express.Router();
router.get('/queue', async (req, res) => {
  // Placeholder: fetch queue depth from Redis/Prometheus
  res.json({ depth: 120 });
});
module.exports = router;
