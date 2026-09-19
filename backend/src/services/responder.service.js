const { Responder } = require('../models');
const { haversineKm } = require('./geo.service');

/**
 * Find available responders within radiusKm of (lat, lng).
 * Returns array of responders with `distance_km` added, sorted ascending.
 */
async function findNearbyResponders(lat, lng, radiusKm = 10, limit = 20) {
    const responders = await Responder.findAll({
        where: { availability: true },
    });

    const withDistance = responders
        .map((r) => {
            const plain = r.get({ plain: true });
            plain.distance_km = haversineKm(lat, lng, plain.lat, plain.lng);
            return plain;
        })
        .filter((r) => r.distance_km <= radiusKm)
        .sort((a, b) => a.distance_km - b.distance_km)
        .slice(0, limit);

    return withDistance;
}

module.exports = { findNearbyResponders };