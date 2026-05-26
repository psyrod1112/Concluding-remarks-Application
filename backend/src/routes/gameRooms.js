const express = require('express');
const pool = require('../db/postgres');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// ── Helper: 방 + 참가자 정보 조회 ──────────────────
async function getRoomWithParticipants(roomId, client) {
    const result = await client.query(`
        SELECT
            gr.id, gr.title,
            (gr.password IS NOT NULL) AS has_password,
            gr.status, gr.max_players, gr.created_at,
            hu.user_id AS host_id, hu.nickname AS host_nickname,
            COALESCE(
                JSON_AGG(
                    JSON_BUILD_OBJECT('userId', pu.user_id, 'nickname', pu.nickname)
                    ORDER BY rp.joined_at
                ) FILTER (WHERE rp.user_id IS NOT NULL),
                '[]'::json
            ) AS participants
        FROM game_rooms gr
        JOIN users hu ON gr.host_id = hu.id
        LEFT JOIN room_participants rp ON gr.id = rp.room_id
        LEFT JOIN users pu ON rp.user_id = pu.id
        WHERE gr.id = $1
        GROUP BY gr.id, hu.user_id, hu.nickname
    `, [roomId]);

    if (result.rows.length === 0) return null;
    const row = result.rows[0];
    return formatRoom(row);
}

function formatRoom(row) {
    return {
        id:            row.id,
        title:         row.title,
        hasPassword:   row.has_password,
        status:        row.status,
        maxPlayers:    row.max_players,
        createdAt:     row.created_at,
        hostId:        row.host_id,
        hostNickname:  row.host_nickname,
        participants:  row.participants ?? [],
    };
}

// ── GET /api/game-rooms — 대기 중인 방 목록 ────────
router.get('/', async (_req, res) => {
    const client = await pool.connect();
    try {
        const result = await client.query(`
            SELECT
                gr.id, gr.title,
                (gr.password IS NOT NULL) AS has_password,
                gr.status, gr.max_players, gr.created_at,
                hu.user_id AS host_id, hu.nickname AS host_nickname,
                COALESCE(
                    JSON_AGG(
                        JSON_BUILD_OBJECT('userId', pu.user_id, 'nickname', pu.nickname)
                        ORDER BY rp.joined_at
                    ) FILTER (WHERE rp.user_id IS NOT NULL),
                    '[]'::json
                ) AS participants
            FROM game_rooms gr
            JOIN users hu ON gr.host_id = hu.id
            LEFT JOIN room_participants rp ON gr.id = rp.room_id
            LEFT JOIN users pu ON rp.user_id = pu.id
            WHERE gr.status = 'waiting'
            GROUP BY gr.id, hu.user_id, hu.nickname
            ORDER BY gr.created_at DESC
            LIMIT 50
        `);
        res.json({ rooms: result.rows.map(formatRoom) });
    } catch (err) {
        console.error('[GameRooms] 목록 조회 오류:', err.message);
        res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    } finally {
        client.release();
    }
});

// ── GET /api/game-rooms/my — 내가 참여 중인 방 (JWT 필요) ──
// /:roomId 보다 먼저 등록해야 라우팅 충돌 없음
router.get('/my', authMiddleware, async (req, res) => {
    const client = await pool.connect();
    try {
        const uuidRes = await client.query(
            'SELECT id FROM users WHERE user_id = $1', [req.user.userId]
        );
        if (uuidRes.rows.length === 0)
            return res.status(401).json({ message: '유저를 찾을 수 없습니다.' });

        const userUuid = uuidRes.rows[0].id;

        const findRes = await client.query(`
            SELECT gr.id FROM room_participants rp
            JOIN game_rooms gr ON rp.room_id = gr.id
            WHERE rp.user_id = $1 AND gr.status = 'waiting'
            LIMIT 1
        `, [userUuid]);

        if (findRes.rows.length === 0)
            return res.status(404).json({ message: '참여 중인 방이 없습니다.' });

        const room = await getRoomWithParticipants(findRes.rows[0].id, client);
        res.json(room);
    } catch (err) {
        console.error('[GameRooms] 내 방 조회 오류:', err.message);
        res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    } finally {
        client.release();
    }
});

// ── POST /api/game-rooms — 방 만들기 (JWT 필요) ────
router.post('/', authMiddleware, async (req, res) => {
    const { title, password } = req.body;

    if (!title || title.trim().length < 2)
        return res.status(400).json({ message: '방 제목은 2자 이상 입력해주세요.' });

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // 유저 UUID 조회
        const uuidRes = await client.query(
            'SELECT id FROM users WHERE user_id = $1', [req.user.userId]
        );
        if (uuidRes.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(401).json({ message: '유저를 찾을 수 없습니다.' });
        }
        const userUuid = uuidRes.rows[0].id;

        // 이미 참여 중인 방 확인
        const existing = await client.query(`
            SELECT gr.id FROM room_participants rp
            JOIN game_rooms gr ON rp.room_id = gr.id
            WHERE rp.user_id = $1 AND gr.status = 'waiting'
        `, [userUuid]);

        if (existing.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(400).json({ message: '이미 다른 방에 참여 중입니다.' });
        }

        // 방 생성
        const roomRes = await client.query(`
            INSERT INTO game_rooms (title, password, host_id)
            VALUES ($1, $2, $3) RETURNING id
        `, [title.trim(), password || null, userUuid]);

        const roomId = roomRes.rows[0].id;

        // 호스트를 참가자로 등록
        await client.query(`
            INSERT INTO room_participants (room_id, user_id) VALUES ($1, $2)
        `, [roomId, userUuid]);

        await client.query('COMMIT');

        const room = await getRoomWithParticipants(roomId, client);
        res.status(201).json({ room });
    } catch (err) {
        await client.query('ROLLBACK');
        console.error('[GameRooms] 방 생성 오류:', err.message);
        res.status(500).json({ message: '방 생성 중 오류가 발생했습니다.' });
    } finally {
        client.release();
    }
});

// ── GET /api/game-rooms/:roomId — 방 상세 ─────────
router.get('/:roomId', async (req, res) => {
    const roomId = parseInt(req.params.roomId);
    if (isNaN(roomId))
        return res.status(400).json({ message: '잘못된 방 ID입니다.' });

    const client = await pool.connect();
    try {
        const room = await getRoomWithParticipants(roomId, client);
        if (!room) return res.status(404).json({ message: '방을 찾을 수 없습니다.' });
        res.json(room);
    } catch (err) {
        console.error('[GameRooms] 방 조회 오류:', err.message);
        res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    } finally {
        client.release();
    }
});

// ── POST /api/game-rooms/:roomId/join — 방 입장 (JWT 필요) ──
router.post('/:roomId/join', authMiddleware, async (req, res) => {
    const roomId = parseInt(req.params.roomId);
    const { password } = req.body;

    if (isNaN(roomId))
        return res.status(400).json({ message: '잘못된 방 ID입니다.' });

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // 유저 UUID 조회
        const uuidRes = await client.query(
            'SELECT id FROM users WHERE user_id = $1', [req.user.userId]
        );
        if (uuidRes.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(401).json({ message: '유저를 찾을 수 없습니다.' });
        }
        const userUuid = uuidRes.rows[0].id;

        // 방 정보 조회
        const roomRes = await client.query(`
            SELECT gr.*, COUNT(rp.user_id)::int AS participant_count
            FROM game_rooms gr
            LEFT JOIN room_participants rp ON gr.id = rp.room_id
            WHERE gr.id = $1
            GROUP BY gr.id
        `, [roomId]);

        if (roomRes.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ message: '방을 찾을 수 없습니다.' });
        }

        const room = roomRes.rows[0];

        // 이미 이 방에 참여 중인지 확인
        const alreadyRes = await client.query(
            'SELECT room_id FROM room_participants WHERE user_id = $1', [userUuid]
        );
        if (alreadyRes.rows.length > 0) {
            await client.query('ROLLBACK');
            if (alreadyRes.rows[0].room_id === roomId)
                return res.status(409).json({ message: '이미 이 방에 참여 중입니다.' });
            return res.status(400).json({ message: '이미 다른 방에 참여 중입니다.' });
        }

        // 방 상태 확인
        if (room.status !== 'waiting') {
            await client.query('ROLLBACK');
            return res.status(409).json({ message: '이미 게임이 시작된 방입니다.' });
        }

        // 인원 확인
        if (room.participant_count >= room.max_players) {
            await client.query('ROLLBACK');
            return res.status(409).json({ message: '방이 가득 찼습니다.' });
        }

        // 비밀번호 확인
        if (room.password != null) {
            if (!password)
                return res.status(422).json({ message: '비밀번호를 입력해주세요.' });
            if (room.password !== password) {
                await client.query('ROLLBACK');
                return res.status(403).json({ message: '비밀번호가 일치하지 않습니다.' });
            }
        }

        // 참가자 추가
        await client.query(
            'INSERT INTO room_participants (room_id, user_id) VALUES ($1, $2)',
            [roomId, userUuid]
        );

        await client.query('COMMIT');

        const updatedRoom = await getRoomWithParticipants(roomId, client);
        res.json({ room: updatedRoom });
    } catch (err) {
        await client.query('ROLLBACK');
        console.error('[GameRooms] 방 입장 오류:', err.message);
        res.status(500).json({ message: '방 입장 중 오류가 발생했습니다.' });
    } finally {
        client.release();
    }
});

// ── POST /api/game-rooms/:roomId/leave — 방 나가기 (JWT 필요) ──
router.post('/:roomId/leave', authMiddleware, async (req, res) => {
    const roomId = parseInt(req.params.roomId);
    if (isNaN(roomId))
        return res.status(400).json({ message: '잘못된 방 ID입니다.' });

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // 유저 UUID 조회
        const uuidRes = await client.query(
            'SELECT id FROM users WHERE user_id = $1', [req.user.userId]
        );
        if (uuidRes.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(401).json({ message: '유저를 찾을 수 없습니다.' });
        }
        const userUuid = uuidRes.rows[0].id;

        // 참가자인지 확인
        const partRes = await client.query(
            'SELECT 1 FROM room_participants WHERE room_id = $1 AND user_id = $2',
            [roomId, userUuid]
        );
        if (partRes.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ message: '참여 중인 방이 아닙니다.' });
        }

        // 방장 여부 확인
        const roomRes = await client.query(
            'SELECT host_id FROM game_rooms WHERE id = $1', [roomId]
        );
        if (roomRes.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ message: '방을 찾을 수 없습니다.' });
        }

        const isHost = roomRes.rows[0].host_id === userUuid;

        if (isHost) {
            // 방장이 나가면 방 삭제 (room_participants는 CASCADE로 자동 삭제)
            await client.query('DELETE FROM game_rooms WHERE id = $1', [roomId]);
        } else {
            // 참가자만 제거
            await client.query(
                'DELETE FROM room_participants WHERE room_id = $1 AND user_id = $2',
                [roomId, userUuid]
            );
        }

        await client.query('COMMIT');
        res.json({ message: '방에서 나갔습니다.' });
    } catch (err) {
        await client.query('ROLLBACK');
        console.error('[GameRooms] 방 나가기 오류:', err.message);
        res.status(500).json({ message: '방 나가기 중 오류가 발생했습니다.' });
    } finally {
        client.release();
    }
});

module.exports = router;
