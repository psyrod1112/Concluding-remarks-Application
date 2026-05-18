require('dotenv').config();
const express = require('express');
const http = require('http');
const { WebSocketServer } = require('ws');
const { router: authRouter } = require('./src/routes/auth');
const pool = require('./src/db/postgres');
const { client: redisClient } = require('./src/db/redis');

const rankingRouter = require('./src/routes/ranking');
const gamelogsRouter = require('./src/routes/gamelogs');
const matchesRouter = require('./src/routes/matches');
const gameRoomsRouter = require('./src/routes/gameRooms');
const usersRouter = require('./src/routes/users');
const communityRouter = require('./src/routes/community');

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

// ── 미들웨어 ──────────────────────────────
app.use(express.json());

// ── CORS (테스트용) ───────────────────────
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PATCH, DELETE, OPTIONS');
    if (req.method === 'OPTIONS') return res.sendStatus(200);
    next();
});

// ── REST API 라우터 ───────────────────────
app.use('/api/auth', authRouter);
app.use('/api/ranking', rankingRouter);
app.use('/api/gamelogs', gamelogsRouter);
app.use('/api/matches', matchesRouter);
app.use('/api/game-rooms', gameRoomsRouter);
app.use('/api/users', usersRouter);
app.use('/api/community', communityRouter);

// ── 헬스체크 ──────────────────────────────
app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.get('/health/detail', async (_req, res) => {
    const result = { status: 'ok', db: {}, redis: {} };

    try {
        const t = Date.now();
        await pool.query('SELECT 1');
        result.db = { ok: true, latencyMs: Date.now() - t };
    } catch (e) {
        result.db = { ok: false, error: e.message };
        result.status = 'degraded';
    }

    try {
        const t = Date.now();
        await redisClient.ping();
        result.redis = { ok: true, latencyMs: Date.now() - t };
    } catch (e) {
        result.redis = { ok: false, error: e.message };
        result.status = 'degraded';
    }

    res.json(result);
});

// ── WebSocket ─────────────────────────────
wss.on('connection', (ws) => {
    console.log('[WS] 클라이언트 연결');

    ws.on('message', (data) => {
        try {
            const packet = JSON.parse(data);
            console.log('[WS] 수신:', packet);
            // 4주차에 패킷 타입별 분기 추가
        } catch {
            ws.send(JSON.stringify({ error: '잘못된 패킷 형식' }));
        }
    });

    ws.on('close', () => console.log('[WS] 클라이언트 연결 종료'));
});

// ── 서버 시작 ─────────────────────────────
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`[서버] 실행 중 → http://localhost:${PORT}`);
});
