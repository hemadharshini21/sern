const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');

const Responder = sequelize.define('Responder', {
    user_id: {
        type: DataTypes.UUID,
        primaryKey: true,
    },
    skills: {
        type: DataTypes.JSONB,
        defaultValue: [],
    },
    availability: {
        type: DataTypes.BOOLEAN,
        defaultValue: true,
    },
    lat: {
        type: DataTypes.FLOAT,
        allowNull: false,
    },
    lng: {
        type: DataTypes.FLOAT,
        allowNull: false,
    },
    avg_response_time: {
        type: DataTypes.FLOAT,
        defaultValue: 0,
    },
    acceptance_rate: {
        type: DataTypes.FLOAT,
        defaultValue: 0,
    },
}, {
    tableName: 'responders',
    timestamps: false,
});

module.exports = Responder;