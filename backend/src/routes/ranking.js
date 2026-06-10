const express = require('express');
const pool = require('../db/postgres');

const router = express.Router();

const PAGE_SIZE = 20;
const MAX_PAGE_SIZE = 100;

// ──────────────────────────────────────────
// GET /api/ranking?page=1&limit=20
//   전체 랭킹 (점수 내림차순, 동점 시 가입 빠른 순)
// ──────────────────────────────────────────
router.get('/', async (req, res) => {
    const page  = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(
        MAX_PAGE_SIZE,
        Math.max(1, parseInt(req.query.limit) || PAGE_SIZE)
    );
    const offset = (page - 1) * limit;

    try {
        const result = await pool.query(
            `SELECT rank, user_id, nickname, score,
                    win_count, lose_count, total_games, win_rate
             FROM v_user_ranking
             ORDER BY rank
             LIMIT $1 OFFSET $2`,
            [limit, offset]
        );

        const countResult = await pool.query(
            `SELECT COUNT(*) AS total FROM users WHERE is_active = TRUE`
        );
        const totalUsers = parseInt(countResult.rows[0].total, 10);

        return res.json({
            page,
            limit,
            totalUsers,
            totalPages: Math.ceil(totalUsers / limit),
            rankings: result.rows.map((r) => ({
                rank:       Number(r.rank),
                userId:     r.user_id,
                nickname:   r.nickname,
                score:      r.score,
                winCount:   r.win_count,
                loseCount:  r.lose_count,
                totalGames: Number(r.total_games),
                winRate:    Number(r.win_rate),
            })),
        });
    } catch (err) {
        console.error('[Ranking] 전체 랭킹 조회 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// ──────────────────────────────────────────
// GET /api/ranking/top?limit=10
//   상위 N명만 (메인 화면용, 기본 10명)
// ──────────────────────────────────────────
router.get('/top', async (req, res) => {
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit) || 10));

    try {
        const result = await pool.query(
            `SELECT rank, user_id, nickname, score, win_rate
             FROM v_user_ranking
             ORDER BY rank
             LIMIT $1`,
            [limit]
        );

        return res.json({
            rankings: result.rows.map((r) => ({
                rank:     Number(r.rank),
                userId:   r.user_id,
                nickname: r.nickname,
                score:    r.score,
                winRate:  Number(r.win_rate),
            })),
        });
    } catch (err) {
        console.error('[Ranking] 상위 랭킹 조회 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// ──────────────────────────────────────────
// GET /api/ranking/:userId
//   특정 유저의 순위 + 주변 순위(앞뒤 2명) 조회
// ──────────────────────────────────────────
router.get('/:userId', async (req, res) => {
    const { userId } = req.params;

    try {
        const meResult = await pool.query(
            `SELECT rank, user_id, nickname, score,
                    win_count, lose_count, total_games, win_rate
             FROM v_user_ranking
             WHERE user_id = $1`,
            [userId]
        );

        if (meResult.rows.length === 0)
            return res.status(404).json({ message: '유저를 찾을 수 없습니다.' });

        const me = meResult.rows[0];
        const myRank = Number(me.rank);

        // 앞뒤 2명씩 (총 최대 5명) 조회
        const neighborResult = await pool.query(
            `SELECT rank, user_id, nickname, score, win_rate
             FROM v_user_ranking
             WHERE rank BETWEEN $1 AND $2
             ORDER BY rank`,
            [Math.max(1, myRank - 2), myRank + 2]
        );

        return res.json({
            me: {
                rank:       myRank,
                userId:     me.user_id,
                nickname:   me.nickname,
                score:      me.score,
                winCount:   me.win_count,
                loseCount:  me.lose_count,
                totalGames: Number(me.total_games),
                winRate:    Number(me.win_rate),
            },
            neighbors: neighborResult.rows.map((r) => ({
                rank:     Number(r.rank),
                userId:   r.user_id,
                nickname: r.nickname,
                score:    r.score,
                winRate:  Number(r.win_rate),
            })),
        });
    } catch (err) {
        console.error('[Ranking] 유저 순위 조회 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

module.exports = router;
