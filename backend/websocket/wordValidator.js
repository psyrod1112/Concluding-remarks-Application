const { isValid } = require('../src/db/wordCache');

/**
 * 끝말잇기 규칙 + 단어 DB 유효성 검사
 * @returns {{ ok: boolean, reason?: string }}
 */
async function validateWord(word, lastWord, usedWords) {
    if (!word || typeof word !== 'string') {
        return { ok: false, reason: '단어를 입력해주세요.' };
    }

    word = word.trim();

    // 끝말잇기 규칙: 마지막 글자로 시작해야 함
    if (lastWord) {
        const lastChar = lastWord[lastWord.length - 1];
        if (word[0] !== lastChar) {
            return { ok: false, reason: `'${lastChar}'(으)로 시작하는 단어를 입력하세요.` };
        }
    }

    // 중복 단어 검사
    if (usedWords.has(word)) {
        return { ok: false, reason: '이미 사용된 단어입니다.' };
    }

    // 사전 검사 (Redis 캐시 → PostgreSQL)
    const exists = await isValid(word);
    if (!exists) {
        return { ok: false, reason: '사전에 없는 단어입니다.' };
    }

    return { ok: true };
}

module.exports = { validateWord };
