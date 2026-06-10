const { isValid } = require('../src/db/wordCache');

const HANGUL_ONLY = /^[가-힣]+$/;
const MIN_WORD_LENGTH = 2;

/**
 * 끝말잇기 규칙 + 단어 DB 유효성 검사
 * @returns {Promise<{ ok: boolean, reason?: string }>}
 */
async function validateWord(word, lastWord, usedWords) {
    if (!word || typeof word !== 'string') {
        return { ok: false, reason: '단어를 입력해주세요.' };
    }

    const normalized = word.trim();

    if (normalized.length < MIN_WORD_LENGTH) {
        return { ok: false, reason: '두 글자 이상의 단어를 입력해주세요.' };
    }

    if (!HANGUL_ONLY.test(normalized)) {
        return { ok: false, reason: '한글 단어만 입력할 수 있습니다.' };
    }

    if (lastWord) {
        const lastChar = Array.from(lastWord).at(-1);
        if (!normalized.startsWith(lastChar)) {
            return { ok: false, reason: `'${lastChar}'(으)로 시작하는 단어를 입력하세요.` };
        }
    }

    if (usedWords.has(normalized)) {
        return { ok: false, reason: '이미 사용된 단어입니다.' };
    }

    if (process.env.WORD_VALIDATION_MODE !== 'loose') {
        const exists = await isValid(normalized);
        if (!exists) {
            return { ok: false, reason: '사전에 없는 단어입니다.' };
        }
    }

    return { ok: true, word: normalized };
}

module.exports = { validateWord };
