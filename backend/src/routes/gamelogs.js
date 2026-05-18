const express = require('express');
const { authMiddleware } = require('./auth');

const router = express.Router();

// GET /api/gamelogs/me
router.get('/me', authMiddleware, (req, res) => {
    return res.json({
        message: '내 게임 기록 조회 엔드포인트',
        user: req.user,
        logs: [],
    });
});

// POST /api/gamelogs
router.post('/', authMiddleware, (req, res) => {
    return res.status(201).json({
        message: '게임 기록 저장 엔드포인트',
        body: req.body,
    });
});

module.exports = router;