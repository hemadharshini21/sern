const { z } = require('zod');

const createIncidentSchema = z.object({
    type: z.string().min(2, 'Incident type required'),
    landmark: z.string().optional(),
    patient: z.enum(['self', 'other']).optional(),
    lat: z.number().min(-90).max(90),
    lng: z.number().min(-180).max(180),
});

const updateStatusSchema = z.object({
    status: z.enum(['pending', 'assigned', 'in_progress', 'arrived', 'completed', 'resolved', 'cancelled']),
});

const listQuerySchema = z.object({
    status: z.enum(['pending', 'assigned', 'in_progress', 'arrived', 'completed', 'resolved', 'cancelled']).optional(),
    limit: z.coerce.number().int().min(1).max(100).optional().default(20),
    offset: z.coerce.number().int().min(0).optional().default(0),
});

module.exports = {
    createIncidentSchema,
    updateStatusSchema,
    listQuerySchema,
};