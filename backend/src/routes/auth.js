const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../db/postgres');
const { client: redisClient } = require('../db/redis');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

const ACCESS_TTL  = Number(process.env.JWT_ACCESS_TTL)  || 900;
const REFRESH_TTL = Number(process.env.JWT_REFRESH_TTL) || 604800;

function signAccessToken(payload) {
    return jwt.sign(payload, process.env.JWT_ACCESS_SECRET, { expiresIn: ACCESS_TTL });
}

function signRefreshToken(payload) {
    return jwt.sign(payload, process.env.JWT_REFRESH_SECRET, { expiresIn: REFRESH_TTL });
}

// ──────────────────────────────────────────
// POST /api/auth/register  —  회원가입
// ──────────────────────────────────────────
router.post('/register', async (req, res) => {
    const { userId, nickname, password } = req.body;

    if (!userId || !nickname || !password)
        return res.status(400).json({ message: '모든 필드를 입력해주세요.' });

    if (userId.length < 4 || userId.length > 30)
        return res.status(400).json({ message: '아이디는 4~30자 사이여야 합니다.' });

    if (nickname.length < 2 || nickname.length > 30)
        return res.status(400).json({ message: '닉네임은 2~30자 사이여야 합니다.' });

    if (password.length < 6)
        return res.status(400).json({ message: '비밀번호는 6자 이상이어야 합니다.' });

    try {
        const exists = await pool.query(
            'SELECT id FROM users WHERE user_id = $1',
            [userId]
        );
        if (exists.rows.length > 0)
            return res.status(409).json({ message: '이미 사용 중인 아이디입니다.' });

        const passwordHash = await bcrypt.hash(password, 10);
        const result = await pool.query(
            `INSERT INTO users (user_id, nickname, password_hash)
             VALUES ($1, $2, $3)
             RETURNING id, user_id, nickname`,
            [userId, nickname, passwordHash]
        );

        const user = result.rows[0];
        return res.status(201).json({
            message: '회원가입 성공',
            user: { id: user.id, userId: user.user_id, nickname: user.nickname },
        });
    } catch (err) {
        console.error('[Auth] 회원가입 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// ──────────────────────────────────────────
// POST /api/auth/login  —  로그인
// ──────────────────────────────────────────
router.post('/login', async (req, res) => {
    const { userId, password } = req.body;

    if (!userId || !password)
        return res.status(400).json({ message: '아이디와 비밀번호를 입력해주세요.' });

    try {
        const result = await pool.query(
            `SELECT id, user_id, nickname, password_hash
             FROM users
             WHERE user_id = $1 AND is_active = TRUE`,
            [userId]
        );

        if (result.rows.length === 0)
            return res.status(401).json({ message: '아이디 또는 비밀번호가 올바르지 않습니다.' });

        const user = result.rows[0];
        const isValid = await bcrypt.compare(password, user.password_hash);
        if (!isValid)
            return res.status(401).json({ message: '아이디 또는 비밀번호가 올바르지 않습니다.' });

        await pool.query(
            'UPDATE users SET last_login_at = NOW() WHERE id = $1',
            [user.id]
        );

        const payload = { userId: user.user_id, nickname: user.nickname };
        const accessToken  = signAccessToken(payload);
        const refreshToken = signRefreshToken(payload);

        await redisClient.setEx(
            `refresh:${refreshToken}`,
            REFRESH_TTL,
            JSON.stringify(payload)
        );

        return res.json({
            message: '로그인 성공',
            accessToken,
            refreshToken,
            user: { id: user.id, userId: user.user_id, nickname: user.nickname },
        });
    } catch (err) {
        console.error('[Auth] 로그인 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// ──────────────────────────────────────────
// POST /api/auth/refresh  —  액세스 토큰 갱신
// body: { refreshToken }
// ──────────────────────────────────────────
router.post('/refresh', async (req, res) => {
    const { refreshToken } = req.body;
    if (!refreshToken)
        return res.status(400).json({ message: 'refreshToken이 필요합니다.' });

    try {
        const payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
        const stored = await redisClient.get(`refresh:${refreshToken}`);
        if (!stored)
            return res.status(401).json({ message: '만료됐거나 유효하지 않은 refreshToken입니다.' });

        const accessToken = signAccessToken({ userId: payload.userId, nickname: payload.nickname });
        return res.json({ accessToken });
    } catch {
        return res.status(401).json({ message: '유효하지 않은 refreshToken입니다.' });
    }
});

// ──────────────────────────────────────────
// GET /api/auth/me  —  내 정보 조회 (인증 필요)
// ──────────────────────────────────────────
router.get('/me', authMiddleware, async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT id, user_id, nickname, score, win_count, lose_count, created_at, last_login_at
             FROM users
             WHERE user_id = $1`,
            [req.user.userId]
        );

        if (result.rows.length === 0)
            return res.status(404).json({ message: '유저를 찾을 수 없습니다.' });

        const u = result.rows[0];
        return res.json({
            id:          u.id,
            userId:      u.user_id,
            nickname:    u.nickname,
            score:       u.score,
            winCount:    u.win_count,
            loseCount:   u.lose_count,
            createdAt:   u.created_at,
            lastLoginAt: u.last_login_at,
        });
    } catch (err) {
        console.error('[Auth] 내 정보 조회 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// ──────────────────────────────────────────
// POST /api/auth/logout  —  로그아웃 (인증 필요)
// body: { refreshToken }
// ──────────────────────────────────────────
router.post('/logout', authMiddleware, async (req, res) => {
    const { refreshToken } = req.body;
    if (refreshToken) {
        await redisClient.del(`refresh:${refreshToken}`);
    }
    return res.json({ message: '로그아웃 성공' });
});

module.exports = { router };
