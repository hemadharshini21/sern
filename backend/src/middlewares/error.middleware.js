const { ZodError } = require('zod');

function notFound(req, res, next) {
    res.status(404).json({ error: `Route not found: ${req.method} ${req.originalUrl}` });
}

function errorHandler(err, req, res, next) {
    // Zod validation errors → 400 with details
    if (err instanceof ZodError) {
        return res.status(400).json({
            error: 'Validation failed',
            details: err.errors.map((e) => ({
                path: e.path.join('.'),
                message: e.message,
            })),
        });
    }

    const status = err.status || 500;
    const message = err.message || 'Internal server error';

    if (status >= 500) {
        console.error('[ERROR]', err);
    }

    res.status(status).json({ error: message });
}

module.exports = { notFound, errorHandler };