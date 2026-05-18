const express = require('express');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// POST /api/matches/random/queue
router.post('/random/queue', authMiddleware, (req, res) => {
    return res.status(202).json({
        message: '랜덤 매칭 대기열 참가 엔드포인트',
        user: req.user,
        status: 'waiting',
        estimatedWaitSeconds: 15,
    });
});

// DELETE /api/matches/random/queue
router.delete('/random/queue', authMiddleware, (req, res) => {
    return res.json({
        message: '랜덤 매칭 취소 엔드포인트',
        user: req.user,
        status: 'cancelled',
    });
});

// GET /api/matches/random/status
router.get('/random/status', authMiddleware, (req, res) => {
    return res.json({
        message: '랜덤 매칭 상태 조회 엔드포인트',
        user: req.user,
        status: 'waiting',
        estimatedWaitSeconds: 15,
        matchedRoomId: null,
    });
});

module.exports = router;