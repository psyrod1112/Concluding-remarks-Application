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

-- game_rooms 테이블
CREATE TABLE IF NOT EXISTS game_rooms (
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(50)  NOT NULL,
    password    VARCHAR(30),
    host_id     UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status      VARCHAR(10)  NOT NULL DEFAULT 'waiting',
    max_players INTEGER      NOT NULL DEFAULT 2,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_game_rooms_host_id ON game_rooms (host_id);
CREATE INDEX IF NOT EXISTS idx_game_rooms_status  ON game_rooms (status);

-- room_participants 테이블
CREATE TABLE IF NOT EXISTS room_participants (
    room_id    INTEGER NOT NULL REFERENCES game_rooms(id) ON DELETE CASCADE,
    user_id    UUID    NOT NULL REFERENCES users(id)      ON DELETE CASCADE,
    joined_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (room_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_room_participants_user_id ON room_participants (user_id);

-- words 테이블 (끝말잇기 사전)
CREATE TABLE IF NOT EXISTS words (
    word   VARCHAR(10) PRIMARY KEY,
    length SMALLINT    NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_words_length ON words (length);

-- game_logs: 경기 기록 (websocket gameSession.js의 INSERT와 컬럼 일치)
CREATE TABLE IF NOT EXISTS game_logs (
    id                   SERIAL PRIMARY KEY,
    winner_id            UUID REFERENCES users(id) ON DELETE SET NULL,
    loser_id             UUID REFERENCES users(id) ON DELETE SET NULL,
    winner_score_change  INTEGER NOT NULL DEFAULT 0,
    played_at            TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT chk_winner_not_loser CHECK (winner_id IS DISTINCT FROM loser_id)
);

CREATE INDEX IF NOT EXISTS idx_game_logs_winner   ON game_logs (winner_id);
CREATE INDEX IF NOT EXISTS idx_game_logs_loser    ON game_logs (loser_id);
CREATE INDEX IF NOT EXISTS idx_game_logs_played   ON game_logs (played_at DESC);

-- 활성 유저 점수 정렬용 부분 인덱스
CREATE INDEX IF NOT EXISTS idx_users_ranking
    ON users (score DESC, created_at ASC)
    WHERE is_active = TRUE;

-- v_user_ranking: 랭킹 뷰 (rank/win_rate/total_games)
CREATE OR REPLACE VIEW v_user_ranking AS
SELECT
    ROW_NUMBER() OVER (ORDER BY score DESC, created_at ASC) AS rank,
    user_id,
    nickname,
    score,
    win_count,
    lose_count,
    (win_count + lose_count) AS total_games,
    CASE
        WHEN (win_count + lose_count) = 0 THEN 0
        ELSE ROUND(win_count::numeric / (win_count + lose_count) * 100)
    END AS win_rate
FROM users
WHERE is_active = TRUE;
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