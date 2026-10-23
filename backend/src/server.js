require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const swaggerUi = require('swagger-ui-express');

const env = require('./config/env');
const { connectDB, sequelize } = require('./config/db');
require('./models');

const swaggerSpec = require('./config/swagger');
const authRoutes = require('./routes/auth.routes');
const incidentRoutes = require('./routes/incident.routes');
const responderRoutes = require('./routes/responder.routes');
const { notFound, errorHandler } = require('./middlewares/error.middleware');

const app = express();
const httpServer = http.createServer(app);

// ─── Socket.IO GPS Hub ────────────────────────────────────────────────────────
const io = new Server(httpServer, {
    cors: { origin: '*', methods: ['GET', 'POST'] },
    pingTimeout: 60000,
    pingInterval: 25000,
});

// In-memory GPS store: { [incidentId]: { lat, lng, speed, heading, timestamp } }
const gpsCache = {};
// Map captainSocketId → incidentId (for cleanup on disconnect)
const captainMap = {};

io.on('connection', (socket) => {
    console.log(`[Socket.IO] Client connected: ${socket.id}`);

    // ── Captain joins an incident room and starts broadcasting GPS ──
    socket.on('captain:join', ({ incidentId, captainId }) => {
        socket.join(`incident:${incidentId}`);
        captainMap[socket.id] = incidentId;
        console.log(`[Socket.IO] Captain ${captainId} joined incident:${incidentId}`);
    });

    // ── Captain pushes real GPS position (every 2–3 sec from driver app) ──
    socket.on('captain:gps', ({ incidentId, lat, lng, speed = 0, heading = 0 }) => {
        const payload = { lat, lng, speed, heading, timestamp: Date.now() };
        gpsCache[incidentId] = payload;

        // Broadcast to all users watching this incident
        io.to(`incident:${incidentId}`).emit('ambulance:position', payload);
    });

    // ── User subscribes to track an incident ──
    socket.on('user:track', ({ incidentId }) => {
        socket.join(`incident:${incidentId}`);
        // Immediately send cached position if available
        if (gpsCache[incidentId]) {
            socket.emit('ambulance:position', gpsCache[incidentId]);
        }
        console.log(`[Socket.IO] User tracking incident:${incidentId}`);
    });

    // ── Incident status change broadcast (from REST → Socket) ──
    socket.on('incident:status', ({ incidentId, status }) => {
        io.to(`incident:${incidentId}`).emit('incident:status', { incidentId, status });
    });

    socket.on('disconnect', () => {
        const incidentId = captainMap[socket.id];
        if (incidentId) {
            delete captainMap[socket.id];
            console.log(`[Socket.IO] Captain disconnected from incident:${incidentId}`);
        }
        console.log(`[Socket.IO] Client disconnected: ${socket.id}`);
    });
});

// Expose io to controllers so REST endpoints can emit events
app.set('io', io);
app.set('gpsCache', gpsCache);

// ─── Rate Limiting ────────────────────────────────────────────────────────────
const globalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 min
    max: 200,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Too many requests. Please try again later.' },
});

const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 20,
    message: { error: 'Too many login attempts. Please try again in 15 minutes.' },
});

const incidentLimiter = rateLimit({
    windowMs: 1 * 60 * 1000, // 1 min
    max: 10,
    message: { error: 'Too many incident requests. Slow down.' },
});

// ─── Global Middleware ────────────────────────────────────────────────────────
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json({ limit: '10kb' })); // prevent large payload attacks
app.use(globalLimiter);

// ─── Swagger ──────────────────────────────────────────────────────────────────
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// ─── Health ───────────────────────────────────────────────────────────────────
app.get('/health', async (req, res) => {
    try {
        await sequelize.query('SELECT 1');
        res.json({
            status: 'ok',
            database: 'connected',
            activeSockets: io.engine.clientsCount,
            trackedIncidents: Object.keys(gpsCache).length,
        });
    } catch (err) {
        res.status(503).json({ status: 'degraded', database: 'disconnected' });
    }
});

// ─── GPS snapshot REST endpoint ───────────────────────────────────────────────
app.get('/gps/:incidentId', (req, res) => {
    const pos = gpsCache[req.params.incidentId];
    if (!pos) return res.status(404).json({ error: 'No GPS data yet' });
    res.json(pos);
});

// ─── Routes ───────────────────────────────────────────────────────────────────
app.use('/auth', authLimiter, authRoutes);
app.use('/incidents', incidentLimiter, incidentRoutes);
app.use('/responders', responderRoutes);

// ─── Error Handlers ───────────────────────────────────────────────────────────
app.use(notFound);
app.use(errorHandler);

// ─── Boot ─────────────────────────────────────────────────────────────────────
async function start() {
    try {
        await connectDB();
        await sequelize.sync();
        console.log('Database synced successfully.');
    } catch (err) {
        console.warn('PostgreSQL connection/sync warning:', err.message);
    }

    httpServer.listen(env.PORT, () => {
        console.log(`✅ SERN backend running on port ${env.PORT}`);
        console.log(`✅ Socket.IO GPS hub active`);
    });
}

start();
