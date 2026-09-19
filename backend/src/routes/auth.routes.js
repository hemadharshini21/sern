const express = require('express');
const router = express.Router();
const { register, login, me } = require('../controllers/auth.controller');
const { requireAuth } = require('../middlewares/auth.middleware');

/**
 * @openapi
 * /auth/register:
 *   post:
 *     tags: [Auth]
 *     summary: Register a new user
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name, email, password]
 *             properties:
 *               name: { type: string, example: Test Citizen }
 *               email: { type: string, example: test@example.com }
 *               password: { type: string, example: secret123 }
 *               phone: { type: string, example: "9876543210" }
 *               role: { type: string, enum: [citizen, responder], example: citizen }
 *     responses:
 *       201:
 *         description: User created
 *       409:
 *         description: Email already registered
 */
router.post('/register', register);

/**
 * @openapi
 * /auth/login:
 *   post:
 *     tags: [Auth]
 *     summary: Login
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, password]
 *             properties:
 *               email: { type: string, example: test@example.com }
 *               password: { type: string, example: secret123 }
 *     responses:
 *       200:
 *         description: Logged in
 *       401:
 *         description: Invalid credentials
 */
router.post('/login', login);

/**
 * @openapi
 * /auth/me:
 *   get:
 *     tags: [Auth]
 *     summary: Get current user
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Current user
 *       401:
 *         description: Unauthorized
 */
router.get('/me', requireAuth, me);

module.exports = router;