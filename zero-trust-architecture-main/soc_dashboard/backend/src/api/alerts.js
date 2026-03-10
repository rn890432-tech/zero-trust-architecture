const express = require('express');
const router = express.Router();
router.get('/', async (req, res) => {
  // Placeholder: fetch alerts from DB
  res.json({ alerts: [] });
});
module.exports = router;
