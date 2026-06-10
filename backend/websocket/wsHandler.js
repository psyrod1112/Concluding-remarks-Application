const jwt = require('jsonwebtoken');
const {
    joinQueue,
    leaveQueue,
    removeFromQueue,
    joinRoom,
    removeFromFriendlyRoom,
} = require('./matchManager');
const { handleWordSubmit, handleDisconnect } = require('./gameSession');

// 인증된 클라이언트 관리: Map<userId, ws>
const clients = new Map();

function initWebSocket(wss) {
    wss.on('connection', (ws) => {
        ws.isAuthenticated = false;
        ws.userId = null;
        ws.nickname = null;
        ws.roomId = null;

        // 5초 안에 auth 없으면 연결 종료
        ws.authTimeout = setTimeout(() => {
            if (!ws.isAuthenticated) {
                ws.close(4001, '인증 시간 초과');
            }
        }, 5000);

        ws.on('message', async (data) => {
            let packet;
            try {
                packet = JSON.parse(data);
            } catch {
                return send(ws, { type: 'error', message: '잘못된 패킷 형식' });
            }

            if (!ws.isAuthenticated) {
                if (packet.type === 'auth') {
                    await handleAuth(ws, packet);
                } else {
                    send(ws, { type: 'error', message: '먼저 인증이 필요합니다.' });
                }
                return;
            }

            switch (packet.type) {
                case 'join_queue':
                    joinQueue(ws);
                    break;
                case 'leave_queue':
                    leaveQueue(ws);
                    break;
                case 'join_room':
                    await joinRoom(ws, packet.roomId);
                    break;
                case 'submit_word':
                    await handleWordSubmit(ws, packet);
                    break;
                default:
                    send(ws, { type: 'error', message: `알 수 없는 패킷: ${packet.type}` });
            }
        });

        ws.on('close', () => {
            clearTimeout(ws.authTimeout);
            if (ws.userId) {
                clients.delete(ws.userId);
                console.log(`[WS] 연결 종료: ${ws.nickname}`);
            }
            removeFromQueue(ws);
            removeFromFriendlyRoom(ws);
            handleDisconnect(ws);
        });

        ws.on('error', (err) => {
            console.error('[WS] 소켓 에러:', err.message);
        });
    });

    console.log('[WS] WebSocket 핸들러 초기화 완료');
}

async function handleAuth(ws, packet) {
    const { accessToken } = packet;

    if (!accessToken) {
        send(ws, { type: 'auth_fail', message: 'accessToken이 없습니다.' });
        return ws.close(4002, '인증 실패');
    }

    let payload;
    try {
        payload = jwt.verify(accessToken, process.env.JWT_ACCESS_SECRET);
    } catch (err) {
        const message = err.name === 'TokenExpiredError'
            ? '토큰이 만료됐습니다. 다시 로그인해주세요.'
            : '유효하지 않은 토큰입니다.';
        send(ws, { type: 'auth_fail', message });
        return ws.close(4003, '토큰 오류');
    }

    // 중복 로그인 처리
    if (clients.has(payload.userId)) {
        const existing = clients.get(payload.userId);
        existing.close(4004, '다른 기기에서 접속되었습니다.');
        clients.delete(payload.userId);
    }

    ws.isAuthenticated = true;
    ws.userId = payload.userId;
    ws.nickname = payload.nickname;
    clearTimeout(ws.authTimeout);

    clients.set(payload.userId, ws);

    send(ws, {
        type: 'auth_success',
        userId: ws.userId,
        nickname: ws.nickname,
    });

    console.log(`[WS] 인증 성공: ${ws.nickname} (${ws.userId})`);
}

function send(ws, payload) {
    if (ws.readyState === ws.OPEN) {
        ws.send(JSON.stringify(payload));
    }
}

module.exports = { initWebSocket, clients, send };
