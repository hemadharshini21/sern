const { Incident, User } = require('../models');
const {
    createIncidentSchema,
    updateStatusSchema,
    listQuerySchema,
} = require('../schemas/incident.schema');
const { predictSeverity, rankResponders } = require('../services/ml.service');
const { findNearbyResponders } = require('../services/responder.service');

async function createIncident(req, res, next) {
    try {
        const data = createIncidentSchema.parse(req.body);

        const incident = await Incident.create({
            citizen_id: req.user.id,
            type: data.type,
            description: data.description || null,
            lat: data.lat,
            lng: data.lng,
        });

        // 1. ML severity prediction (non-blocking on failure)
        let severityResult = { severity: 'pending', confidence: 0 };
        try {
            severityResult = await predictSeverity({
                type: data.type,
                description: data.description,
                lat: data.lat,
                lng: data.lng,
            });
            incident.severity = severityResult.severity;
            await incident.save();
        } catch (err) {
            console.error('[ML severity failed]', err.message);
        }

        // 2. Find nearby responders + rank via ML
        let ranked = [];
        try {
            const nearby = await findNearbyResponders(data.lat, data.lng, 10, 20);
            if (nearby.length > 0) {
                ranked = await rankResponders({
                    incidentType: data.type,
                    lat: data.lat,
                    lng: data.lng,
                    responders: nearby,
                });
            }
        } catch (err) {
            console.error('[ML ranking failed]', err.message);
        }

        res.status(201).json({
            incident,
            severity: severityResult,
            ranked_responders: ranked,
        });
    } catch (err) {
        next(err);
    }
}

async function listIncidents(req, res, next) {
    try {
        const query = listQuerySchema.parse(req.query);

        const where = {};
        if (req.user.role !== 'admin') {
            where.citizen_id = req.user.id;
        }
        if (query.status) {
            where.status = query.status;
        }

        const { count, rows } = await Incident.findAndCountAll({
            where,
            limit: query.limit,
            offset: query.offset,
            order: [['created_at', 'DESC']],
        });

        res.json({ total: count, limit: query.limit, offset: query.offset, incidents: rows });
    } catch (err) {
        next(err);
    }
}

async function getIncident(req, res, next) {
    try {
        const incident = await Incident.findByPk(req.params.id, {
            include: [{ model: User, as: 'citizen', attributes: ['id', 'name', 'email', 'phone'] }],
        });

        if (!incident) {
            return res.status(404).json({ error: 'Incident not found' });
        }

        if (req.user.role !== 'admin' && incident.citizen_id !== req.user.id) {
            return res.status(403).json({ error: 'Forbidden' });
        }

        res.json({ incident });
    } catch (err) {
        next(err);
    }
}

async function updateStatus(req, res, next) {
    try {
        const data = updateStatusSchema.parse(req.body);

        const incident = await Incident.findByPk(req.params.id);
        if (!incident) {
            return res.status(404).json({ error: 'Incident not found' });
        }

        if (req.user.role !== 'admin' && incident.citizen_id !== req.user.id) {
            return res.status(403).json({ error: 'Forbidden' });
        }

        incident.status = data.status;
        if (data.status === 'resolved' || data.status === 'cancelled') {
            incident.closed_at = new Date();
        }
        await incident.save();

        res.json({ incident });
    } catch (err) {
        next(err);
    }
}

module.exports = { createIncident, listIncidents, getIncident, updateStatus };