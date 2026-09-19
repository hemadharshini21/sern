const swaggerJsdoc = require('swagger-jsdoc');
const env = require('./env');

const options = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'SERN API',
            version: '1.0.0',
            description: 'Smart Emergency Response Network — Backend API',
        },
        tags: [
            { name: 'Auth', description: 'Authentication & users' },
            { name: 'Incidents', description: 'SOS incidents' },
            { name: 'Responders', description: 'Responder discovery' },
        ],
        servers: [
            { url: `http://localhost:${env.PORT}`, description: 'Local dev' },
        ],
        components: {
            securitySchemes: {
                bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
            },
        },
    },
    apis: ['./src/routes/*.js'],
};
module.exports = swaggerJsdoc(options);