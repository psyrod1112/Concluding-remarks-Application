require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
    host:     process.env.DB_HOST,
    port:     process.env.DB_PORT,
    database: process.env.DB_NAME,
    user:     process.env.DB_USER,
    password: process.env.DB_PASSWORD,
});

const sql = `
-- users 스탯 컬럼 추가
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS win_count  INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS lose_count INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS score      INTEGER NOT NULL DEFAULT 1000;

-- posts 테이블
CREATE TABLE IF NOT EXISTS posts (
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(100)  NOT NULL,
    content     TEXT          NOT NULL,
    category    VARCHAR(20)   NOT NULL DEFAULT '자유',
    view_count  INTEGER       NOT NULL DEFAULT 0,
    author_id   UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_posts_author_id  ON posts (author_id);
CREATE INDEX IF NOT EXISTS idx_posts_category   ON posts (category);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts (created_at DESC);

DROP TRIGGER IF EXISTS trigger_posts_updated_at ON posts;
CREATE TRIGGER trigger_posts_updated_at
    BEFORE UPDATE ON posts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- comments 테이블
CREATE TABLE IF NOT EXISTS comments (
    id          SERIAL PRIMARY KEY,
    post_id     INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    content     TEXT    NOT NULL,
    author_id   UUID    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments (post_id);

-- games 테이블 (1v1 끝말잇기 대전 기록)
CREATE TABLE IF NOT EXISTS games (
    id                    SERIAL PRIMARY KEY,
    player1_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    player2_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    winner_id             UUID REFERENCES users(id) ON DELETE SET NULL,
    player1_score_before  INTEGER NOT NULL,
    player1_score_after   INTEGER NOT NULL,
    player2_score_before  INTEGER NOT NULL,
    player2_score_after   INTEGER NOT NULL,
    word_chain            JSONB NOT NULL DEFAULT '[]'::jsonb,
    end_reason            VARCHAR(20) NOT NULL,
    duration_seconds      INTEGER NOT NULL DEFAULT 0,
    played_at             TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_games_distinct_players
        CHECK (player1_id <> player2_id),
    CONSTRAINT chk_games_winner_is_participant
        CHECK (winner_id IS NULL OR winner_id = player1_id OR winner_id = player2_id),
    CONSTRAINT chk_games_end_reason
        CHECK (end_reason IN ('win', 'timeout', 'invalid_word', 'disconnect', 'draw'))
);

CREATE INDEX IF NOT EXISTS idx_games_player1_played_at
    ON games (player1_id, played_at DESC);
CREATE INDEX IF NOT EXISTS idx_games_player2_played_at
    ON games (player2_id, played_at DESC);
CREATE INDEX IF NOT EXISTS idx_games_played_at
    ON games (played_at DESC);

-- 랭킹 조회 최적화용 인덱스 (score 내림차순, 동점자 가입 빠른 순)
CREATE INDEX IF NOT EXISTS idx_users_ranking
    ON users (score DESC, created_at ASC)
    WHERE is_active = true;

-- 랭킹 조회용 view
CREATE OR REPLACE VIEW v_user_ranking AS
SELECT
    ROW_NUMBER() OVER (ORDER BY score DESC, created_at ASC) AS rank,
    id,
    username,
    score,
    win_count,
    lose_count,
    (win_count + lose_count) AS total_games,
    CASE
        WHEN (win_count + lose_count) = 0 THEN 0
        ELSE ROUND(win_count * 100.0 / (win_count + lose_count), 1)
    END AS win_rate
FROM users
WHERE is_active = true;

-- words 테이블 (끝말잇기 사전)
CREATE TABLE IF NOT EXISTS words (
    word        VARCHAR(20) PRIMARY KEY,
    length      INTEGER NOT NULL,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_words_length_match
        CHECK (length = char_length(word)),
    CONSTRAINT chk_words_length_positive
        CHECK (length >= 1)
);

CREATE INDEX IF NOT EXISTS idx_words_length ON words (length);
`;

async function migrate() {
    const client = await pool.connect();
    try {
        await client.query(sql);
        console.log('마이그레이션 완료');
    } catch (err) {
        console.error('마이그레이션 실패:', err.message);
    } finally {
        client.release();
        await pool.end();
    }
}

migrate();