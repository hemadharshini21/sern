require('dotenv').config();
const responderRoutes = require('./routes/responder.routes');
const incidentRoutes = require('./routes/incident.routes');
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const swaggerUi = require('swagger-ui-express');

const env = require('./config/env');
const { connectDB, sequelize } = require('./config/db');
require('./models');

const swaggerSpec = require('./config/swagger');
const authRoutes = require('./routes/auth.routes');
const { notFound, errorHandler } = require('./middlewares/error.middleware');

const app = express();

// Global middleware
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

// Swagger docs
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Health
app.get('/health', async (req, res) => {
    try {
        await sequelize.query('SELECT 1');
        res.json({ status: 'ok', database: 'connected' });
    } catch (err) {
        res.status(503).json({ status: 'degraded', database: 'disconnected' });
    }
});

// Routes
app.use('/auth', authRoutes);
app.use('/incidents', incidentRoutes);
app.use('/responders', responderRoutes);
// 404 + error handlers (must be last)
app.use(notFound);
app.use(errorHandler);

// Boot
async function start() {
    try {
        await connectDB();
        await sequelize.sync({ alter: true });
        app.listen(env.PORT, () => {
            console.log(`SERN backend running on port ${env.PORT}`);
        });
    } catch (err) {
        console.error('Failed to start server:', err);
        process.exit(1);
    }
}

start();