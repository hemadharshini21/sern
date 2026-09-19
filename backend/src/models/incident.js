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
    },
    type: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    description: {
        type: DataTypes.TEXT,
        allowNull: true,
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