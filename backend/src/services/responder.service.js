const { sequelize } = require('../config/db');
const { QueryTypes } = require('sequelize');
const { haversineKm } = require('./geo.service');

const DEFAULT_MOCK_RESPONDERS = [
    {
        user_id: 'amb-101',
        name: 'Apollo Emergency Unit 1',
        vehicle_number: 'KA-01-EQ-9921',
        equipment: ['ALS'],
        skills: ['ALS'],
        lat: 12.9750,
        lng: 77.5980,
        avg_response_time: 4.5,
        acceptance_rate: 0.98,
        rating: 4.9,
        available: true,
    },
    {
        user_id: 'amb-102',
        name: 'Fortis Rapid Response 3',
        vehicle_number: 'KA-03-EM-4412',
        equipment: ['BLS'],
        skills: ['BLS'],
        lat: 12.9680,
        lng: 77.5910,
        avg_response_time: 6.2,
        acceptance_rate: 0.92,
        rating: 4.7,
        available: true,
    },
    {
        user_id: 'amb-103',
        name: 'Manipal Mobile ICU Transport',
        vehicle_number: 'KA-05-MC-1109',
        equipment: ['ALS', 'BLS'],
        skills: ['ALS', 'BLS'],
        lat: 12.9820,
        lng: 77.6050,
        avg_response_time: 5.1,
        acceptance_rate: 0.95,
        rating: 4.95,
        available: true,
    },
];

/**
 * Find available ambulances within radiusKm of (lat, lng) using PostGIS ST_DWithin.
 * Returns array of ambulances with `distance_km` added, sorted ascending.
 */
async function findNearbyResponders(lat, lng, radiusKm = 15, limit = 20) {
    const radiusMeters = radiusKm * 1000;
    try {
        if (sequelize) {
            const sql = `
                SELECT 
                    id AS user_id,
                    vehicle_number,
                    name,
                    lat,
                    lng,
                    skills AS equipment,
                    skills,
                    avg_response_min AS avg_response_time,
                    acceptance_rate,
                    available,
                    ROUND((ST_Distance(geom, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography) / 1000.0)::numeric, 3)::float AS distance_km
                FROM ambulances
                WHERE available = true
                  AND ST_DWithin(geom, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography, :radiusMeters)
                ORDER BY distance_km ASC
                LIMIT :limit;
            `;
            const results = await sequelize.query(sql, {
                replacements: { lat, lng, radiusMeters, limit },
                type: QueryTypes.SELECT,
            });
            if (results && results.length > 0) {
                return results;
            }
        }
    } catch (err) {
        console.warn('[responder.service] PostGIS query fallback:', err.message);
    }

    // In-memory Haversine fallback if PostGIS query returns empty or errors out
    const withDistance = DEFAULT_MOCK_RESPONDERS
        .map((r) => ({
            ...r,
            distance_km: haversineKm(lat, lng, r.lat, r.lng),
        }))
        .filter((r) => r.distance_km <= radiusKm)
        .sort((a, b) => a.distance_km - b.distance_km)
        .slice(0, limit);

    return withDistance;
}

module.exports = { findNearbyResponders };