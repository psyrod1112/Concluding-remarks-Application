const express = require('express');
const pool = require('../db/postgres');

const router = express.Router();

// GET /api/ranking
router.get('/', async (req, res) => {
    const limit = Math.min(Math.max(parseInt(req.query.limit) || 50, 1), 100);

    try {
        const result = await pool.query(
            `SELECT user_id, nickname, score, win_count, lose_count
             FROM users
             WHERE is_active = TRUE
             ORDER BY score DESC, win_count DESC, lose_count ASC, created_at ASC
             LIMIT $1`,
            [limit]
        );

        return res.json({
            rankings: result.rows.map((row, index) => ({
                rank:      index + 1,
                userId:    row.user_id,
                nickname:  row.nickname,
                score:     row.score,
                winCount:  row.win_count,
                loseCount: row.lose_count,
                winRate:   row.win_count + row.lose_count === 0
                    ? 0
                    : Math.round((row.win_count / (row.win_count + row.lose_count)) * 100),
            })),
        });
    } catch (err) {
        console.error('[Ranking] 조회 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

module.exports = router;
