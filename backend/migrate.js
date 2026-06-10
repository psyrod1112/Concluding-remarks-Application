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

-- 기본 테스트 단어 시드
-- 전체 사전 CSV를 넣기 전에도 사과 -> 과일/과자 같은 기본 흐름은 바로 테스트 가능하게 한다.
INSERT INTO words (word, length)
VALUES
    ('사과', 2),
    ('과일', 2),
    ('과자', 2),
    ('일기', 2),
    ('일요일', 3),
    ('일상', 2),
    ('기차', 2),
    ('기린', 2),
    ('기계', 2),
    ('차고', 2),
    ('자동차', 3),
    ('자전거', 3),
    ('자두', 2),
    ('자석', 2),
    ('고래', 2),
    ('고기', 2),
    ('고양이', 3),
    ('라디오', 3),
    ('도시', 2),
    ('시계', 2),
    ('계단', 2),
    ('단어', 2),
    ('어머니', 3),
    ('니트', 2),
    ('트럭', 2),
    ('럭비', 2),
    ('비누', 2),
    ('누나', 2),
    ('나무', 2),
    ('무지개', 3),
    ('개미', 2),
    ('미소', 2),
    ('소나기', 3),
    ('기름', 2),
    ('름름이', 3),
    ('이불', 2),
    ('불고기', 3),
    ('기분', 2),
    ('분필', 2),
    ('필통', 2),
    ('통나무', 3),
    ('학교', 2),
    ('교실', 2),
    ('실내', 2),
    ('내일', 2),
    ('일본', 2),
    ('본능', 2),
    ('능력', 2),
    ('역사', 2),
    ('사람', 2),
    ('람보', 2),
    ('보석', 2),
    ('석류', 2),
    ('유리', 2),
    ('리본', 2),
    ('본드', 2),
    ('드라마', 3),
    ('마음', 2),
    ('음악', 2),
    ('악기', 2)
ON CONFLICT (word) DO NOTHING;

-- game_logs 테이블 (완료된 게임 기록)
CREATE TABLE IF NOT EXISTS game_logs (
    id            SERIAL PRIMARY KEY,
    room_id       INTEGER REFERENCES game_rooms(id) ON DELETE SET NULL,
    room_type     VARCHAR(20) NOT NULL DEFAULT 'friendly',
    winner_id     UUID REFERENCES users(id) ON DELETE SET NULL,
    loser_id      UUID REFERENCES users(id) ON DELETE SET NULL,
    participants  JSONB NOT NULL DEFAULT '[]'::jsonb,
    used_words    JSONB NOT NULL DEFAULT '[]'::jsonb,
    scores        JSONB NOT NULL DEFAULT '{}'::jsonb,
    reason        VARCHAR(30) NOT NULL,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_game_logs_winner_id ON game_logs (winner_id);
CREATE INDEX IF NOT EXISTS idx_game_logs_loser_id  ON game_logs (loser_id);
CREATE INDEX IF NOT EXISTS idx_game_logs_created_at ON game_logs (created_at DESC);
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
