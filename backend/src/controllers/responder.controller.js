const { findNearbyResponders } = require('../services/responder.service');

async function getNearby(req, res, next) {
    try {
        const lat = parseFloat(req.query.lat);
        const lng = parseFloat(req.query.lng);
        const radius = req.query.radius ? parseFloat(req.query.radius) : 10;
        const limit = req.query.limit ? parseInt(req.query.limit, 10) : 20;

        if (Number.isNaN(lat) || Number.isNaN(lng)) {
            return res.status(400).json({ error: 'lat and lng query params required' });
        }
        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
            return res.status(400).json({ error: 'lat/lng out of range' });
        }

        const responders = await findNearbyResponders(lat, lng, radius, limit);
        res.json({ count: responders.length, radius_km: radius, responders });
    } catch (err) {
        next(err);
    }
}

module.exports = { getNearby };