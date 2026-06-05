const { createGameSession } = require('./gameSession');

// 랜덤 매칭 대기열: [ws, ...]
const queue = [];

function joinQueue(ws) {
    // 이미 대기 중이면 무시
    if (queue.find(p => p.userId === ws.userId)) {
        return send(ws, { type: 'error', message: '이미 대기 중입니다.' });
    }

    // 연결이 살아있는 상대를 찾을 때까지 큐에서 꺼냄 (유령 제거)
    let opponent = null;
    while (queue.length > 0) {
        const candidate = queue.shift();
        if (candidate.readyState === candidate.OPEN && candidate.userId !== ws.userId) {
            opponent = candidate;
            break;
        }
        // 끊긴 후보는 버림 (큐에서 이미 제거됨)
    }

    if (opponent) {
        matchPlayers(ws, opponent);
    } else {
        queue.push(ws);
        send(ws, { type: 'queue_joined', message: '상대방을 찾는 중...' });
        console.log(`[매칭] 대기열 등록: ${ws.nickname} (대기: ${queue.length}명)`);
    }
}

function leaveQueue(ws) {
    const idx = queue.findIndex(p => p.userId === ws.userId);
    if (idx !== -1) {
        queue.splice(idx, 1);
        send(ws, { type: 'queue_left' });
        console.log(`[매칭] 대기열 취소: ${ws.nickname}`);
    }
}

// 연결 끊김 시 대기열에서 제거 (응답 없이 조용히)
function removeFromQueue(ws) {
    const idx = queue.findIndex(p => p.userId === ws.userId);
    if (idx !== -1) {
        queue.splice(idx, 1);
        console.log(`[매칭] 연결 끊김으로 대기열 제거: ${ws.nickname}`);
    }
}

function matchPlayers(ws1, ws2) {
    const roomId = Math.random().toString(36).substring(2, 10).toUpperCase();

    console.log(`[매칭] 매칭 성공: ${ws1.nickname} vs ${ws2.nickname} (방: ${roomId})`);

    // 선공 랜덤 결정
    const [first, second] = Math.random() < 0.5 ? [ws1, ws2] : [ws2, ws1];

    createGameSession(roomId, first, second);

    send(first, {
        type: 'match_found',
        roomId,
        opponent: second.nickname,
        isMyTurn: true,
        message: '첫 단어를 입력하세요!',
    });

    send(second, {
        type: 'match_found',
        roomId,
        opponent: first.nickname,
        isMyTurn: false,
        message: '상대방이 먼저 시작합니다.',
    });
}

function send(ws, payload) {
    if (ws.readyState === ws.OPEN) {
        ws.send(JSON.stringify(payload));
    }
}

module.exports = { joinQueue, leaveQueue, removeFromQueue };
