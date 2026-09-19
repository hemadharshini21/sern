const express = require('express');
const router = express.Router();
const { getNearby } = require('../controllers/responder.controller');
const { requireAuth } = require('../middlewares/auth.middleware');

/**
 * @openapi
 * /responders/nearby:
 *   get:
 *     tags: [Responders]
 *     summary: Find available responders near a location
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: lat
 *         required: true
 *         schema: { type: number, example: 12.9716 }
 *       - in: query
 *         name: lng
 *         required: true
 *         schema: { type: number, example: 77.5946 }
 *       - in: query
 *         name: radius
 *         schema: { type: number, default: 10, description: radius in km }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200:
 *         description: List of responders sorted by distance
 *       400:
 *         description: Invalid lat/lng
 */
router.get('/nearby', requireAuth, getNearby);

module.exports = router;