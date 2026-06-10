const express = require('express');
const pool = require('../db/postgres');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

const waitingQueue = [];
const matchedRoomsByUserId = new Map();

function makeRoomId() {
    return `random-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

async function loadPlayer(userId) {
    const result = await pool.query(
        `SELECT user_id, nickname, score, win_count, lose_count
         FROM users
         WHERE user_id = $1 AND is_active = TRUE`,
        [userId]
    );

    if (result.rows.length === 0) return null;
    const row = result.rows[0];
    return {
        userId:    row.user_id,
        nickname:  row.nickname,
        score:     row.score,
        winCount:  row.win_count,
        loseCount: row.lose_count,
    };
}

function removeFromQueue(userId) {
    const index = waitingQueue.findIndex((entry) => entry.userId === userId);
    if (index >= 0) waitingQueue.splice(index, 1);
}

function formatMatchedResponse(match, userId) {
    const opponent = match.players.find((player) => player.userId !== userId);
    return {
        status: 'matched',
        roomId: match.roomId,
        roomType: 'random',
        opponent,
    };
}

// POST /api/matches/random/queue
router.post('/random/queue', authMiddleware, async (req, res) => {
    try {
        const currentUserId = req.user.userId;
        const existingMatch = matchedRoomsByUserId.get(currentUserId);
        if (existingMatch) {
            return res.status(200).json(formatMatchedResponse(existingMatch, currentUserId));
        }

        const player = await loadPlayer(currentUserId);
        if (!player)
            return res.status(404).json({ message: '유저를 찾을 수 없습니다.' });

        removeFromQueue(currentUserId);

        const opponent = waitingQueue.shift();
        if (!opponent) {
            waitingQueue.push({ ...player, queuedAt: Date.now() });
            return res.status(202).json({
                status: 'waiting',
                estimatedWaitSeconds: 15,
            });
        }

        const match = {
            roomId: makeRoomId(),
            players: [opponent, player],
            matchedAt: Date.now(),
        };

        matchedRoomsByUserId.set(opponent.userId, match);
        matchedRoomsByUserId.set(player.userId, match);

        return res.status(201).json(formatMatchedResponse(match, currentUserId));
    } catch (err) {
        console.error('[Matches] 랜덤 매칭 참가 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// DELETE /api/matches/random/queue
router.delete('/random/queue', authMiddleware, (req, res) => {
    removeFromQueue(req.user.userId);
    matchedRoomsByUserId.delete(req.user.userId);

    return res.json({
        status: 'cancelled',
    });
});

// GET /api/matches/random/status
router.get('/random/status', authMiddleware, (req, res) => {
    const userId = req.user.userId;
    const match = matchedRoomsByUserId.get(userId);
    if (match) {
        return res.json(formatMatchedResponse(match, userId));
    }

    const queued = waitingQueue.some((entry) => entry.userId === userId);
    return res.json({
        status: queued ? 'waiting' : 'idle',
        estimatedWaitSeconds: queued ? 15 : null,
        roomId: null,
        opponent: null,
    });
});

module.exports = router;
