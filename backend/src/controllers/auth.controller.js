const { User } = require('../models');
const {
    hashPassword,
    comparePassword,
    signAccessToken,
    signRefreshToken,
} = require('../services/auth.service');
const { registerSchema, loginSchema } = require('../schemas/auth.schema');

function publicUser(user) {
    return {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        created_at: user.created_at,
    };
}

async function register(req, res, next) {
    try {
        const data = registerSchema.parse(req.body);

        const existing = await User.findOne({ where: { email: data.email } });
        if (existing) {
            return res.status(409).json({ error: 'Email already registered' });
        }

        const password_hash = await hashPassword(data.password);
        const user = await User.create({
            name: data.name,
            email: data.email,
            phone: data.phone || null,
            password_hash,
            role: data.role || 'citizen',
        });

        const payload = { id: user.id, role: user.role };
        res.status(201).json({
            user: publicUser(user),
            accessToken: signAccessToken(payload),
            refreshToken: signRefreshToken(payload),
        });
    } catch (err) {
        next(err);
    }
}

async function login(req, res, next) {
    try {
        const data = loginSchema.parse(req.body);

        const user = await User.findOne({ where: { email: data.email } });
        if (!user) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        const ok = await comparePassword(data.password, user.password_hash);
        if (!ok) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        const payload = { id: user.id, role: user.role };
        res.json({
            user: publicUser(user),
            accessToken: signAccessToken(payload),
            refreshToken: signRefreshToken(payload),
        });
    } catch (err) {
        next(err);
    }
}

async function me(req, res, next) {
    try {
        const user = await User.findByPk(req.user.id);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.json({ user: publicUser(user) });
    } catch (err) {
        next(err);
    }
}

module.exports = { register, login, me };