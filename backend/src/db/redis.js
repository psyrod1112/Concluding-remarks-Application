const { createClient } = require('redis');
require('dotenv').config();

const client = createClient({
    socket: {
        host: process.env.REDIS_HOST,
        port: Number(process.env.REDIS_PORT),
    }
});

client.on('error', (err) => console.error('[Redis] 오류:', err.message));
client.connect().then(() => console.log('[Redis] 연결 성공'));

const SESSION_TTL = Number(process.env.SESSION_TTL) || 3600;

// 세션 CRUD
const sessionStore = {
    // 세션 저장
    async set(sessionId, userData) {
        await client.setEx(
            `session:${sessionId}`,
            SESSION_TTL,
            JSON.stringify(userData)
        );
    },

    // 세션 조회
    async get(sessionId) {
        const data = await client.get(`session:${sessionId}`);
        return data ? JSON.parse(data) : null;
    },

    // 세션 삭제 (로그아웃)
    async delete(sessionId) {
        await client.del(`session:${sessionId}`);
    },

    // TTL 갱신 (요청마다 호출해서 활성 유저 세션 유지)
    async refresh(sessionId) {
        await client.expire(`session:${sessionId}`, SESSION_TTL);
    }
};

module.exports = { client, sessionStore };
