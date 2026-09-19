const { Sequelize } = require('sequelize');
const {
    DB_HOST,
    DB_PORT,
    DB_NAME,
    DB_USER,
    DB_PASSWORD,
    NODE_ENV,
} = require('./env');

const sequelize = new Sequelize(DB_NAME, DB_USER, DB_PASSWORD, {
    host: DB_HOST,
    port: DB_PORT,
    dialect: 'postgres',
    logging: NODE_ENV === 'development' ? console.log : false,
    pool: {
        max: 5,
        min: 0,
        acquire: 30000,
        idle: 10000,
    },
});

async function connectDB() {
    try {
        await sequelize.authenticate();
        console.log('PostgreSQL connected successfully.');
        return sequelize;
    } catch (error) {
        console.error('PostgreSQL connection failed:', error.message);
        throw error;
    }
}

module.exports = {
    sequelize,
    connectDB,
};
