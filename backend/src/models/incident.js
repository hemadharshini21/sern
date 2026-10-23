const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');

const Incident = sequelize.define('Incident', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    citizen_id: {
        type: DataTypes.UUID,
        allowNull: false,
        field: 'user_id',
    },
    type: {
        type: DataTypes.STRING,
        allowNull: false,
        field: 'incident_type',
    },
    description: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
    patient: {
        type: DataTypes.ENUM('self', 'other'),
        defaultValue: 'self',
        allowNull: false,
    },
    severity: {
        type: DataTypes.ENUM('pending', 'low', 'medium', 'high', 'critical'),
        defaultValue: 'pending',
        allowNull: false,
    },
    lat: {
        type: DataTypes.FLOAT,
        allowNull: false,
    },
    lng: {
        type: DataTypes.FLOAT,
        allowNull: false,
    },
    status: {
        type: DataTypes.ENUM('pending', 'assigned', 'in_progress', 'resolved', 'cancelled'),
        defaultValue: 'pending',
        allowNull: false,
    },
    closed_at: {
        type: DataTypes.DATE,
        allowNull: true,
    },
}, {
    tableName: 'incidents',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false,
});

module.exports = Incident;