const express = require('express');
const router = express.Router();
const {
    createIncident,
    listIncidents,
    getIncident,
    updateStatus,
} = require('../controllers/incident.controller');
const { requireAuth } = require('../middlewares/auth.middleware');

/**
 * @openapi
 * /incidents:
 *   post:
 *     tags: [Incidents]
 *     summary: Trigger a new SOS incident
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [type, lat, lng]
 *             properties:
 *               type: { type: string, example: medical }
 *               description: { type: string, example: "Person collapsed, needs ambulance" }
 *               lat: { type: number, example: 12.9716 }
 *               lng: { type: number, example: 77.5946 }
 *     responses:
 *       201:
 *         description: Incident created
 *       400:
 *         description: Validation error
 */
router.post('/', requireAuth, createIncident);

/**
 * @openapi
 * /incidents:
 *   get:
 *     tags: [Incidents]
 *     summary: List incidents (citizens see own, admins see all)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema: { type: string, enum: [pending, assigned, in_progress, resolved, cancelled] }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *       - in: query
 *         name: offset
 *         schema: { type: integer, default: 0 }
 *     responses:
 *       200:
 *         description: List of incidents
 */
router.get('/', requireAuth, listIncidents);

/**
 * @openapi
 * /incidents/{id}:
 *   get:
 *     tags: [Incidents]
 *     summary: Get one incident by ID
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Incident details
 *       404:
 *         description: Not found
 */
router.get('/:id', requireAuth, getIncident);

/**
 * @openapi
 * /incidents/{id}/status:
 *   patch:
 *     tags: [Incidents]
 *     summary: Update incident status
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [status]
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [pending, assigned, in_progress, resolved, cancelled]
 *     responses:
 *       200:
 *         description: Status updated
 */
router.patch('/:id/status', requireAuth, updateStatus);

module.exports = router;