const axios = require('axios');
const env = require('../config/env');

const ML_URL = env.ML_SERVICE_URL || 'http://localhost:8000';

async function predictSeverity({ type, description, lat, lng }) {
    const hour = new Date().getHours();
    const { data } = await axios.post(`${ML_URL}/ml/severity`, {
        type,
        description,
        hour,
        lat,
        lng,
    });
    return data; // { severity, confidence }
}

async function rankResponders({ incidentType, lat, lng, responders }) {
    const { data } = await axios.post(`${ML_URL}/ml/rank-responders`, {
        incident_type: incidentType,
        incident_lat: lat,
        incident_lng: lng,
        responders: responders.map((r) => ({
            user_id: r.user_id,
            lat: r.lat,
            lng: r.lng,
            skills: r.skills || [],
            avg_response_time: r.avg_response_time || 0,
            acceptance_rate: r.acceptance_rate || 0,
        })),
    });
    return data.ranked; // [{ user_id, match_score, distance_km }, ...]
}

module.exports = { predictSeverity, rankResponders };