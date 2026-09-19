const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

const env = {
    NODE_ENV: process.env.NODE_ENV || 'development',
    PORT: Number(process.env.PORT) || 3000,
    JWT_SECRET: process.env.JWT_SECRET || 'change_this_to_a_long_random_string',
    DB_HOST: process.env.DB_HOST || 'localhost',
    DB_PORT: Number(process.env.DB_PORT) || 5432,
    DB_NAME: process.env.DB_NAME || 'sern',
    DB_USER: process.env.DB_USER || 'postgres',
    DB_PASSWORD: process.env.DB_PASSWORD || '',
    ML_SERVICE_URL: process.env.ML_SERVICE_URL || 'http://localhost:8000',
};

module.exports = env;
