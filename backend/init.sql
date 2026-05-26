-- UUID 확장
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- updated_at 자동 업데이트 트리거 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- users 테이블
CREATE TABLE IF NOT EXISTS users (
    id              UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         VARCHAR(30)  UNIQUE NOT NULL,
    nickname        VARCHAR(30)  NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    win_count       INTEGER      NOT NULL DEFAULT 0,
    lose_count      INTEGER      NOT NULL DEFAULT 0,
    score           INTEGER      NOT NULL DEFAULT 1000,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at   TIMESTAMP WITH TIME ZONE
);
