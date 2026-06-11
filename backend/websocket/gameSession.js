const pool = require('../src/db/postgres');
const { validateWord } = require('./wordValidator');

const TURN_TIME = Number(process.env.TURN_TIME) || 30;
const MAX_LIVES = 5;

const sessions = new Map();

function createGameSession(roomId, first, second, options = {}) {
    const roomType = options.roomType || 'random';
    const dbRoomId = options.dbRoomId || null;
    const session = {
        roomId,
        roomType,
        dbRoomId,
        players: [
            { ws: first, userId: first.userId, nickname: first.nickname, lives: MAX_LIVES },
            { ws: second, userId: second.userId, nickname: second.nickname, lives: MAX_LIVES },
        ],
        turnIdx: 0,
        lastWord: null,
        usedWords: new Set(),
        timer: null,
        ended: false,
        startedAt: new Date(),
    };

    sessions.set(roomId, session);
    first.roomId = roomId;
    second.roomId = roomId;

    console.log(`[게임] 세션 생성: ${roomId} | ${first.nickname} vs ${second.nickname}`);

    broadcast(session, {
        type: 'game_start',
        roomId,
        players: session.players.map((p) => ({ nickname: p.nickname, lives: p.lives })),
        turnTime: TURN_TIME,
    });

    startTurn(session);
}

function startTurn(session) {
    if (session.ended) return;
    const current = session.players[session.turnIdx];

    broadcast(session, {
        type: 'turn_start',
        turn: current.nickname,
        lastWord: session.lastWord,
        timeLimit: TURN_TIME,
    });

    session.timer = setTimeout(() => handleTimeout(session), TURN_TIME * 1000);
}

async function handleWordSubmit(ws, packet) {
    const session = sessions.get(ws.roomId);
    if (!session || session.ended) return;

    const current = session.players[session.turnIdx];

    if (current.ws !== ws) {
        return send(ws, { type: 'error', message: '지금은 당신의 차례가 아닙니다.' });
    }

    const word = (packet.word || '').trim();
    const result = await validateWord(word, session.lastWord, session.usedWords);

    if (session.ended) return;

    if (!result.ok) {
        send(ws, { type: 'word_invalid', reason: result.reason });
        return;
    }

    clearTimeout(session.timer);
    session.usedWords.add(word);
    session.lastWord = word;

    broadcast(session, {
        type: 'word_accepted',
        word,
        submittedBy: current.nickname,
    });

    session.turnIdx = 1 - session.turnIdx;
    startTurn(session);
}

function handleTimeout(session) {
    if (session.ended) return;
    const current = session.players[session.turnIdx];
    current.lives -= 1;

    console.log(`[게임] 시간 초과: ${current.nickname} (남은 목숨: ${current.lives})`);

    broadcast(session, {
        type: 'timeout',
        player: current.nickname,
        livesLeft: current.lives,
    });

    if (current.lives <= 0) {
        const winner = session.players[1 - session.turnIdx];
        endGame(session, winner, current);
        return;
    }

    startTurn(session);
}

async function endGame(session, winner, loser) {
    if (session.ended) return;
    session.ended = true;
    clearTimeout(session.timer);

    console.log(`[게임] 종료 - 승자: ${winner.nickname} / 패자: ${loser.nickname}`);

    const K = 32;
    const winnerScore = await getUserScore(winner.userId);
    const loserScore = await getUserScore(loser.userId);
    const expected = 1 / (1 + Math.pow(10, (loserScore - winnerScore) / 400));
    const delta = Math.round(K * (1 - expected));

    try {
        await pool.query(
            `UPDATE users SET score = score + $1, win_count = win_count + 1 WHERE user_id = $2`,
            [delta, winner.userId]
        );
        await pool.query(
            `UPDATE users SET score = GREATEST(0, score - $1), lose_count = lose_count + 1 WHERE user_id = $2`,
            [delta, loser.userId]
        );

        const participants = session.players.map((player) => ({
            userId: player.userId,
            nickname: player.nickname,
            lives: player.lives,
        }));
        const scores = {
            [winner.userId]: delta,
            [loser.userId]: -delta,
        };

        await pool.query(
            `INSERT INTO game_logs
                (room_id, room_type, winner_id, loser_id, participants, used_words, scores, reason, winner_score_change)
             SELECT $7, $8, u1.id, u2.id, $3::jsonb, $4::jsonb, $5::jsonb, $6, $9
             FROM users u1, users u2
             WHERE u1.user_id = $1 AND u2.user_id = $2`,
            [
                winner.userId,
                loser.userId,
                JSON.stringify(participants),
                JSON.stringify(Array.from(session.usedWords)),
                JSON.stringify(scores),
                'finished',
                session.dbRoomId,
                session.roomType,
                delta,
            ]
        );
    } catch (err) {
        console.error('[게임] DB 업데이트 실패:', err.message);
    }

    broadcast(session, {
        type: 'game_over',
        winner: winner.nickname,
        loser: loser.nickname,
        scoreChange: delta,
    });

    sessions.delete(session.roomId);
}

async function getUserScore(userId) {
    try {
        const result = await pool.query(
            'SELECT score FROM users WHERE user_id = $1',
            [userId]
        );
        return result.rows[0]?.score ?? 1000;
    } catch {
        return 1000;
    }
}

function handleDisconnect(ws) {
    if (!ws.roomId) return;
    const session = sessions.get(ws.roomId);
    if (!session) return;

    clearTimeout(session.timer);

    const opponent = session.players.find((p) => p.ws !== ws);
    if (opponent) {
        send(opponent.ws, {
            type: 'opponent_disconnected',
            message: '상대방 연결이 끊어졌습니다. 승리 처리합니다.',
        });

        const disconnected = session.players.find((p) => p.ws === ws);
        if (disconnected) endGame(session, opponent, disconnected);
    }
}

function broadcast(session, payload) {
    const msg = JSON.stringify(payload);
    for (const p of session.players) {
        if (p.ws.readyState === p.ws.OPEN) p.ws.send(msg);
    }
}

function send(ws, payload) {
    if (ws.readyState === ws.OPEN) ws.send(JSON.stringify(payload));
}

module.exports = { createGameSession, handleWordSubmit, handleDisconnect };
