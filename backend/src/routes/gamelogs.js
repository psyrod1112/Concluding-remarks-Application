const express = require('express');
const pool = require('../db/postgres');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// GET /api/gamelogs/me
router.get('/me', authMiddleware, async (req, res) => {
    const limit = Math.min(Math.max(parseInt(req.query.limit) || 20, 1), 100);

    try {
        const userResult = await pool.query(
            'SELECT id FROM users WHERE user_id = $1',
            [req.user.userId]
        );

        if (userResult.rows.length === 0)
            return res.status(404).json({ message: '유저를 찾을 수 없습니다.' });

        const userUuid = userResult.rows[0].id;
        const logsResult = await pool.query(
            `SELECT gl.id, gl.room_id, gl.room_type, gl.participants,
                    gl.used_words, gl.scores, gl.reason, gl.created_at,
                    wu.user_id AS winner_user_id, wu.nickname AS winner_nickname,
                    lu.user_id AS loser_user_id, lu.nickname AS loser_nickname
             FROM game_logs gl
             LEFT JOIN users wu ON wu.id = gl.winner_id
             LEFT JOIN users lu ON lu.id = gl.loser_id
             WHERE gl.winner_id = $1 OR gl.loser_id = $1
             ORDER BY gl.created_at DESC
             LIMIT $2`,
            [userUuid, limit]
        );

        return res.json({
            logs: logsResult.rows.map((row) => ({
                id:             row.id,
                roomId:         row.room_id,
                roomType:       row.room_type,
                participants:   row.participants,
                usedWords:      row.used_words,
                scores:         row.scores,
                reason:         row.reason,
                createdAt:      row.created_at,
                winnerUserId:   row.winner_user_id,
                winnerNickname: row.winner_nickname,
                loserUserId:    row.loser_user_id,
                loserNickname:  row.loser_nickname,
                result:         row.winner_user_id === req.user.userId ? 'win' : 'lose',
            })),
        });
    } catch (err) {
        console.error('[GameLogs] 내 기록 조회 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// POST /api/gamelogs
router.post('/', authMiddleware, (_req, res) => {
    return res.status(405).json({ message: '게임 기록은 서버 게임 세션에서 자동 저장됩니다.' });
});

module.exports = router;
