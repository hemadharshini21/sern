require('dotenv').config();
const { connectDB, sequelize } = require('../src/config/db');
const { User, Responder } = require('../src/models');
const { hashPassword } = require('../src/services/auth.service');
// Mock responders around Bangalore (lat 12.9716, lng 77.5946)
const MOCK_RESPONDERS = [
    { name: 'Arjun Kumar', email: 'arjun@test.com', lat: 12.9750, lng: 77.6000, skills: ['medical', 'first_aid'], avg_response_time: 8.5, acceptance_rate: 0.85 },
    { name: 'Priya Sharma', email: 'priya@test.com', lat: 12.9650, lng: 77.5850, skills: ['fire', 'rescue'], avg_response_time: 12.0, acceptance_rate: 0.72 },
    { name: 'Rahul Verma', email: 'rahul@test.com', lat: 12.9800, lng: 77.5900, skills: ['medical'], avg_response_time: 6.2, acceptance_rate: 0.91 },
    { name: 'Sneha Reddy', email: 'sneha@test.com', lat: 12.9600, lng: 77.6100, skills: ['police', 'security'], avg_response_time: 9.8, acceptance_rate: 0.80 },
    { name: 'Vikram Singh', email: 'vikram@test.com', lat: 12.9900, lng: 77.5750, skills: ['medical', 'fire'], avg_response_time: 10.4, acceptance_rate: 0.75 },
];

async function seed() {
    try {
        await connectDB();
        await sequelize.sync({ alter: false });

        const password_hash = await hashPassword('secret123');

        for (const r of MOCK_RESPONDERS) {
            const [user] = await User.findOrCreate({
                where: { email: r.email },
                defaults: {
                    name: r.name,
                    email: r.email,
                    role: 'responder',
                    password_hash,
                },
            });

            await Responder.upsert({
                user_id: user.id,
                skills: r.skills,
                availability: true,
                lat: r.lat,
                lng: r.lng,
                avg_response_time: r.avg_response_time,
                acceptance_rate: r.acceptance_rate,
            });

            console.log(`Seeded responder: ${r.name}`);
        }

        console.log('Done.');
        process.exit(0);
    } catch (err) {
        console.error('Seed failed:', err);
        process.exit(1);
    }
}

seed();