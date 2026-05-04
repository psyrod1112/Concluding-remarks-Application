const express = require('express');
const { authMiddleware } = require('./auth');

const router = express.Router();

// GET /api/users/me/profile
router.get('/me/profile', authMiddleware, (req, res) => {
    return res.json({
        message: '내 프로필 조회 엔드포인트',
        profile: {
            id: req.user.userId,
            username: req.user.username,
            email: req.user.email,
            tier: 'Bronze',
            rankPoint: 0,
            profileImageUrl: null,
        },
    });
});

// GET /api/users/me/stats
router.get('/me/stats', authMiddleware, (req, res) => {
    return res.json({
        message: '내 전적 조회 엔드포인트',
        stats: {
            totalGames: 0,
            wins: 0,
            losses: 0,
            winRate: 0,
            rankGames: {
                totalGames: 0,
                wins: 0,
                losses: 0,
            },
            normalGames: {
                totalGames: 0,
                wins: 0,
                losses: 0,
            },
        },
    });
});

// GET /api/users/:userId/records
router.get('/:userId/records', (req, res) => {
    return res.json({
        message: '특정 유저 전적 조회 엔드포인트',
        userId: req.params.userId,
        records: {
            totalGames: 0,
            wins: 0,
            losses: 0,
            winRate: 0,
            tier: 'Bronze',
        },
    });
});

// PATCH /api/users/me/password
router.patch('/me/password', authMiddleware, (req, res) => {
    return res.json({
        message: '비밀번호 변경 엔드포인트',
    });
});

// DELETE /api/users/me
router.delete('/me', authMiddleware, (req, res) => {
    return res.json({
        message: '회원탈퇴 엔드포인트',
    });
});

module.exports = router;