const pool = require('./postgres');
const { client: redis } = require('./redis');

const KEY_PREFIX = 'word:';
const TTL_INVALID = 3600;  // 없는 단어는 1시간만 캐싱 (크롤러로 추가될 가능성)
// 있는 단어는 TTL 없음 (영구) — 사전은 안 바뀜

/**
 * 단어가 사전에 존재하는지 확인합니다.
 * Redis 캐시 우선, miss 시 PostgreSQL 조회 후 캐싱합니다.
 *
 * @param {string} word - 검증할 단어
 * @returns {Promise<boolean>}
 */
async function isValid(word) {
    if (typeof word !== 'string' || word.length === 0) {
        return false;
    }

    const key = KEY_PREFIX + word;

    // 1. Redis 조회
    try {
        const cached = await redis.get(key);
        if (cached === '1') return true;
        if (cached === '0') return false;
    } catch (err) {
        // Redis 장애 시 DB로 fallback (게임을 멈추지 않음)
        console.error('[wordCache] Redis 조회 실패, DB로 fallback:', err.message);
    }

    // 2. DB 조회 (cache miss)
    let exists = false;
    try {
        const result = await pool.query(
            'SELECT 1 FROM words WHERE word = $1 LIMIT 1',
            [word]
        );
        exists = result.rowCount > 0;
    } catch (err) {
        console.error('[wordCache] DB 조회 실패:', err.message);
        // DB도 죽으면 보수적으로 false 반환 (잘못된 단어를 통과시키지 않음)
        return false;
    }

    // 3. Redis에 결과 캐싱 (실패해도 무시)
    try {
        if (exists) {
            await redis.set(key, '1');  // 영구
        } else {
            await redis.setEx(key, TTL_INVALID, '0');  // 1시간
        }
    } catch (err) {
        console.error('[wordCache] Redis 캐싱 실패:', err.message);
    }

    return exists;
}

/**
 * 단어를 미리 캐시에 적재합니다 (크롤러가 단어 INSERT 후 호출).
 * 호출 안 해도 isValid 첫 호출 시 자동 캐싱되므로 선택사항입니다.
 *
 * @param {string} word
 * @returns {Promise<void>}
 */
async function preload(word) {
    if (typeof word !== 'string' || word.length === 0) return;
    try {
        await redis.set(KEY_PREFIX + word, '1');
    } catch (err) {
        console.error('[wordCache] preload 실패:', err.message);
    }
}

/**
 * 캐시에서 단어를 제거합니다 (단어 삭제/수정 시 호출).
 *
 * @param {string} word
 * @returns {Promise<void>}
 */
async function invalidate(word) {
    if (typeof word !== 'string' || word.length === 0) return;
    try {
        await redis.del(KEY_PREFIX + word);
    } catch (err) {
        console.error('[wordCache] invalidate 실패:', err.message);
    }
}

module.exports = { isValid, preload, invalidate };