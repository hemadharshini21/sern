const { sequelize } = require('../config/db');
const User = require('./user');
const Incident = require('./incident');
const Responder = require('./responder');

// Associations
User.hasMany(Incident, { foreignKey: 'citizen_id', as: 'incidents' });
Incident.belongsTo(User, { foreignKey: 'citizen_id', as: 'citizen' });

User.hasOne(Responder, { foreignKey: 'user_id', as: 'responder_profile' });
Responder.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

module.exports = {
    sequelize,
    User,
    Incident,
    Responder,
};