/**
 * 한국어 단어 사전을 words 테이블에 일괄 적재합니다.
 *
 * 데이터 출처: https://github.com/korean-word-game/db
 *   - 국립국어원 표준국어대사전(2018.11.13) 발췌
 *   - 저작권: 단순 낱말 수집은 한국어 자체로 저작권 보호 대상 아님 (자유 배포 가능)
 *
 * 사용법:
 *   1. https://drive.google.com/open?id=1PdzYubqcPKAIsHRtWZEFdQ1m4-fba6Oj 에서
 *      kr_korean.csv 다운로드
 *   2. backend/scripts/data/kr_korean.csv 경로에 저장
 *   3. cd backend && node scripts/import-words.js
 *
 * 필터링 규칙:
 *   - 품사: 명사만 ('명사' 정확히 일치)
 *   - 글자수: 2~5글자 (1글자 단어는 끝말잇기에 부적합, 6글자 이상은 거의 안 쓰임)
 *   - 형식: 한글 음절만 (가-힣). 한자, 영문, 숫자, 공백, 특수문자 포함 단어 제외
 *   - 중복: PK 충돌 시 무시 (ON CONFLICT DO NOTHING)
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const pool = require('../src/db/postgres');

const CSV_PATH = process.argv[2] || path.join(__dirname, 'data', 'kr_korean.csv');
const BATCH_SIZE = 1000;          // 한 번에 INSERT할 단어 수
const MIN_LENGTH = 2;             // 최소 글자수
const MAX_LENGTH = 5;             // 최대 글자수
const HANGUL_ONLY = /^[가-힣]+$/; // 순수 한글 음절만

/**
 * 단어 한 개를 검사해서 적재 대상인지 판단합니다.
 * @param {string} word
 * @param {string} part - 품사 문자열
 * @returns {boolean}
 */
function shouldImport(word, part) {
    if (!word || !part) return false;
    if (part.trim() !== '명사') return false;
    if (word.length < MIN_LENGTH || word.length > MAX_LENGTH) return false;
    if (!HANGUL_ONLY.test(word)) return false;
    return true;
}

/**
 * 배치 단위로 words 테이블에 INSERT 합니다.
 * 한 번에 1000개씩 묶어서 보내면 row-by-row INSERT보다 50배 이상 빠릅니다.
 *
 * @param {Array<string>} batch - 단어 배열
 * @returns {Promise<number>} 실제로 INSERT된 row 수 (중복 제외)
 */
async function insertBatch(batch) {
    if (batch.length === 0) return 0;

    // PostgreSQL multi-row INSERT 쿼리 구성:
    //   INSERT INTO words (word, length) VALUES ($1, $2), ($3, $4), ...
    //   ON CONFLICT (word) DO NOTHING
    const values = [];
    const placeholders = batch.map((word, i) => {
        const offset = i * 2;
        values.push(word, word.length);
        return `($${offset + 1}, $${offset + 2})`;
    });

    const query = `
        INSERT INTO words (word, length)
        VALUES ${placeholders.join(', ')}
        ON CONFLICT (word) DO NOTHING
    `;

    const result = await pool.query(query, values);
    return result.rowCount;
}

/**
 * CSV 파일을 한 줄씩 스트리밍으로 읽어서 필터링/적재합니다.
 * 9MB 파일을 메모리에 한꺼번에 올리지 않기 위해 readline 스트림을 사용합니다.
 */
async function importWords() {
    // 파일 존재 확인
    if (!fs.existsSync(CSV_PATH)) {
        console.error(`[import-words] CSV 파일이 없습니다: ${CSV_PATH}`);
        console.error('[import-words] README의 다운로드 안내를 참고하세요.');
        process.exit(1);
    }

    console.log(`[import-words] CSV 읽기 시작: ${CSV_PATH}`);

    const rl = readline.createInterface({
        input: fs.createReadStream(CSV_PATH, { encoding: 'utf-8' }),
        crlfDelay: Infinity,
    });

    let totalRead = 0;       // CSV에서 읽은 총 줄 수
    let totalFiltered = 0;   // 필터 통과한 단어 수
    let totalInserted = 0;   // 실제로 DB에 들어간 단어 수 (중복 제외)
    let batch = [];
    const startTime = Date.now();

    for await (const line of rl) {
        totalRead++;

        // CSV 한 줄 파싱: "낱말,품사" 형식
        // 단순 split으로 충분 (이 데이터는 따옴표/이스케이프 없음)
        const [word, part] = line.split(',').map(s => s && s.trim());

        if (!shouldImport(word, part)) continue;
        totalFiltered++;
        batch.push(word);

        // 배치가 차면 INSERT
        if (batch.length >= BATCH_SIZE) {
            const inserted = await insertBatch(batch);
            totalInserted += inserted;
            batch = [];

            // 진행률 로깅 (10000줄마다)
            if (totalRead % 10000 === 0) {
                console.log(
                    `[import-words] 진행: ${totalRead}줄 읽음, ` +
                    `${totalFiltered}개 필터 통과, ${totalInserted}개 적재됨`
                );
            }
        }
    }

    // 마지막 잔여 배치 처리
    if (batch.length > 0) {
        const inserted = await insertBatch(batch);
        totalInserted += inserted;
    }

    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
    console.log('');
    console.log('[import-words] 완료');
    console.log(`  - 총 읽은 줄:     ${totalRead}`);
    console.log(`  - 필터 통과:      ${totalFiltered}`);
    console.log(`  - 실제 적재:      ${totalInserted} (중복 ${totalFiltered - totalInserted}개 제외)`);
    console.log(`  - 소요 시간:      ${elapsed}초`);
}

importWords()
    .then(() => pool.end())
    .catch(err => {
        console.error('[import-words] 실패:', err);
        pool.end();
        process.exit(1);
    });