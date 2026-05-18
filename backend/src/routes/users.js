const express = require('express');
const pool = require('../db/postgres');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// GET /api/users/:userId/stats
router.get('/:userId/stats', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT user_id, nickname, score, win_count, lose_count
             FROM users
             WHERE user_id = $1 AND is_active = TRUE`,
            [req.params.userId]
        );

        if (result.rows.length === 0)
            return res.status(404).json({ message: '유저를 찾을 수 없습니다.' });

        const u = result.rows[0];
        return res.json({
            userId:    u.user_id,
            nickname:  u.nickname,
            score:     u.score,
            winCount:  u.win_count,
            loseCount: u.lose_count,
            winRate:   u.win_count + u.lose_count === 0
                ? 0
                : Math.round((u.win_count / (u.win_count + u.lose_count)) * 100),
        });
    } catch (err) {
        console.error('[Users] stats 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// GET /api/users/me/profile  (인증 필요)
router.get('/me/profile', authMiddleware, async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT user_id, nickname, score, win_count, lose_count
             FROM users
             WHERE user_id = $1`,
            [req.user.userId]
        );

        if (result.rows.length === 0)
            return res.status(404).json({ message: '유저를 찾을 수 없습니다.' });

        const u = result.rows[0];
        return res.json({
            userId:    u.user_id,
            nickname:  u.nickname,
            score:     u.score,
            winCount:  u.win_count,
            loseCount: u.lose_count,
        });
    } catch (err) {
        console.error('[Users] profile 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// PATCH /api/users/me/password  (인증 필요)
router.patch('/me/password', authMiddleware, (req, res) => {
    return res.json({ message: '비밀번호 변경 엔드포인트 (미구현)' });
});

// DELETE /api/users/me  (인증 필요)
router.delete('/me', authMiddleware, (req, res) => {
    return res.json({ message: '회원탈퇴 엔드포인트 (미구현)' });
});

module.exports = router;
