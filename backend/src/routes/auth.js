const express = require('express');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const pool = require('../db/postgres');
const { sessionStore } = require('../db/redis');

const router = express.Router();

// ──────────────────────────────────────────
// 미들웨어: 세션 검증
// 사용법: 보호 라우트에 authMiddleware 인자로 추가
// ──────────────────────────────────────────
const authMiddleware = async (req, res, next) => {
    const sessionId = req.headers.authorization?.split(' ')[1]; // Bearer <sessionId>
    if (!sessionId)
        return res.status(401).json({ message: '로그인이 필요합니다.' });

    const session = await sessionStore.get(sessionId);
    if (!session)
        return res.status(401).json({ message: '세션이 만료됐습니다. 다시 로그인해주세요.' });

    req.user = session;
    await sessionStore.refresh(sessionId); // 활동 시 TTL 갱신
    next();
};

// ──────────────────────────────────────────
// POST /api/auth/register  —  회원가입
// body: { username, email, password }
// ──────────────────────────────────────────
router.post('/register', async (req, res) => {
    const { username, email, password } = req.body;

    if (!username || !email || !password)
        return res.status(400).json({ message: '모든 필드를 입력해주세요.' });

    if (username.length < 2 || username.length > 30)
        return res.status(400).json({ message: '닉네임은 2~30자 사이여야 합니다.' });

    if (password.length < 6)
        return res.status(400).json({ message: '비밀번호는 6자 이상이어야 합니다.' });

    try {
        // 이메일/닉네임 중복 확인
        const exists = await pool.query(
            'SELECT id FROM users WHERE email = $1 OR username = $2',
            [email, username]
        );
        if (exists.rows.length > 0)
            return res.status(409).json({ message: '이미 사용 중인 이메일 또는 닉네임입니다.' });

        const passwordHash = await bcrypt.hash(password, 10);

        const result = await pool.query(
            `INSERT INTO users (username, email, password_hash)
             VALUES ($1, $2, $3)
             RETURNING id, username, email, created_at`,
            [username, email, passwordHash]
        );

        const user = result.rows[0];

        // 회원가입 즉시 세션 발급
        const sessionId = crypto.randomUUID();
        await sessionStore.set(sessionId, {
            userId:    user.id,
            username:  user.username,
            email:     user.email,
            createdAt: new Date().toISOString(),
        });

        return res.status(201).json({
            message: '회원가입 성공',
            sessionId,
            user: { id: user.id, username: user.username, email: user.email }
        });

    } catch (err) {
        console.error('[Auth] 회원가입 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// ──────────────────────────────────────────
// POST /api/auth/login  —  로그인
// body: { email, password }
// ──────────────────────────────────────────
router.post('/login', async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password)
        return res.status(400).json({ message: '이메일과 비밀번호를 입력해주세요.' });

    try {
        const result = await pool.query(
            `SELECT id, username, email, password_hash
             FROM users
             WHERE email = $1 AND is_active = TRUE`,
            [email]
        );

        if (result.rows.length === 0)
            return res.status(401).json({ message: '이메일 또는 비밀번호가 올바르지 않습니다.' });

        const user = result.rows[0];
        const isValid = await bcrypt.compare(password, user.password_hash);

        if (!isValid)
            return res.status(401).json({ message: '이메일 또는 비밀번호가 올바르지 않습니다.' });

        // 마지막 로그인 시각 업데이트
        await pool.query(
            'UPDATE users SET last_login_at = NOW() WHERE id = $1',
            [user.id]
        );

        // 세션 발급
        const sessionId = crypto.randomUUID();
        await sessionStore.set(sessionId, {
            userId:    user.id,
            username:  user.username,
            email:     user.email,
            createdAt: new Date().toISOString(),
        });

        return res.json({
            message: '로그인 성공',
            sessionId,
            user: { id: user.id, username: user.username, email: user.email }
        });

    } catch (err) {
        console.error('[Auth] 로그인 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// ──────────────────────────────────────────
// GET /api/auth/me  —  내 정보 조회 (세션 필요)
// ──────────────────────────────────────────
router.get('/me', authMiddleware, async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT id, username, email, created_at, last_login_at
             FROM users
             WHERE id = $1`,
            [req.user.userId]
        );

        if (result.rows.length === 0)
            return res.status(404).json({ message: '유저를 찾을 수 없습니다.' });

        return res.json(result.rows[0]);

    } catch (err) {
        console.error('[Auth] 내 정보 조회 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// ──────────────────────────────────────────
// POST /api/auth/logout  —  로그아웃 (세션 필요)
// ──────────────────────────────────────────
router.post('/logout', authMiddleware, async (req, res) => {
    const sessionId = req.headers.authorization?.split(' ')[1];
    await sessionStore.delete(sessionId);
    return res.json({ message: '로그아웃 성공' });
});

module.exports = { router, authMiddleware };
