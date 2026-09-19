const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const env = require('../config/env');

const SALT_ROUNDS = 10;

async function hashPassword(plain) {
    return bcrypt.hash(plain, SALT_ROUNDS);
}

async function comparePassword(plain, hash) {
    return bcrypt.compare(plain, hash);
}

function signAccessToken(payload) {
    return jwt.sign(payload, env.JWT_SECRET, { expiresIn: '1h' });
}

function signRefreshToken(payload) {
    return jwt.sign(payload, env.JWT_SECRET, { expiresIn: '7d' });
}

function verifyToken(token) {
    return jwt.verify(token, env.JWT_SECRET);
}

module.exports = {
    hashPassword,
    comparePassword,
    signAccessToken,
    signRefreshToken,
    verifyToken,
};