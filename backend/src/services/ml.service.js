const axios = require('axios');
const env = require('../config/env');

const ML_URL = env.ML_SERVICE_URL || 'http://localhost:8000';

async function predictSeverity({ type, incident_type }) {
    const hour = new Date().getHours();
    const { data } = await axios.post(`${ML_URL}/ml/severity`, {
        incident_type: incident_type || type,
        type: type || incident_type,
        hour,
    });
    return data; // { severity, confidence }
}

async function rankResponders({ severity, incidentType, lat, lng, responders }) {
    const { data } = await axios.post(`${ML_URL}/ml/rank-ambulances`, {
        severity: severity || incidentType,
        incident_type: incidentType || severity,
        incident_lat: lat,
        incident_lng: lng,
        responders: responders.map((r) => ({
            user_id: r.user_id || r.id,
            lat: r.lat,
            lng: r.lng,
            equipment: r.equipment || r.skills || [],
            skills: r.skills || r.equipment || [],
            avg_response_time: r.avg_response_time || 0,
            acceptance_rate: r.acceptance_rate || 0,
        })),
    });
    return data.ranked || data; // Handles array or { ranked: [...] }
}

module.exports = { predictSeverity, rankResponders };