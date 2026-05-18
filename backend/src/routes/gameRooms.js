const express = require('express');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// POST /api/game-rooms
router.post('/', authMiddleware, (req, res) => {
    return res.status(201).json({
        message: '게임방 생성 엔드포인트',
        room: {
            id: 'temp-room-id',
            mode: req.body.mode || 'normal',
            players: [req.user],
            status: 'waiting',
        },
    });
});

// GET /api/game-rooms/:roomId
router.get('/:roomId', authMiddleware, (req, res) => {
    return res.json({
        message: '게임방 조회 엔드포인트',
        roomId: req.params.roomId,
        room: {
            id: req.params.roomId,
            status: 'waiting',
            players: [],
            currentTurnUserId: null,
        },
    });
});

// POST /api/game-rooms/:roomId/join
router.post('/:roomId/join', authMiddleware, (req, res) => {
    return res.json({
        message: '게임방 입장 엔드포인트',
        roomId: req.params.roomId,
        user: req.user,
    });
});

// POST /api/game-rooms/:roomId/leave
router.post('/:roomId/leave', authMiddleware, (req, res) => {
    return res.json({
        message: '게임방 퇴장 엔드포인트',
        roomId: req.params.roomId,
        user: req.user,
    });
});

module.exports = router;