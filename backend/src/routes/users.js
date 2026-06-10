const express = require('express');
const bcrypt = require('bcrypt');
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
router.patch('/me/password', authMiddleware, async (req, res) => {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword)
        return res.status(400).json({ message: '현재 비밀번호와 새 비밀번호를 입력해주세요.' });

    if (newPassword.length < 6)
        return res.status(400).json({ message: '새 비밀번호는 6자 이상이어야 합니다.' });

    try {
        const result = await pool.query(
            'SELECT id, password_hash FROM users WHERE user_id = $1 AND is_active = TRUE',
            [req.user.userId]
        );

        if (result.rows.length === 0)
            return res.status(404).json({ message: '유저를 찾을 수 없습니다.' });

        const user = result.rows[0];
        const isValid = await bcrypt.compare(currentPassword, user.password_hash);
        if (!isValid)
            return res.status(401).json({ message: '현재 비밀번호가 일치하지 않습니다.' });

        const nextHash = await bcrypt.hash(newPassword, 10);
        await pool.query(
            'UPDATE users SET password_hash = $1 WHERE id = $2',
            [nextHash, user.id]
        );

        return res.json({ message: '비밀번호를 변경했습니다.' });
    } catch (err) {
        console.error('[Users] password 변경 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// DELETE /api/users/me  (인증 필요)
router.delete('/me', authMiddleware, async (req, res) => {
    try {
        const result = await pool.query(
            `UPDATE users
             SET is_active = FALSE
             WHERE user_id = $1 AND is_active = TRUE
             RETURNING user_id`,
            [req.user.userId]
        );

        if (result.rows.length === 0)
            return res.status(404).json({ message: '유저를 찾을 수 없습니다.' });

        return res.json({ message: '회원탈퇴가 완료되었습니다.' });
    } catch (err) {
        console.error('[Users] 회원탈퇴 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

module.exports = router;
