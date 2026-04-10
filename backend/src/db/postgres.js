const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    host:     process.env.DB_HOST,
    port:     process.env.DB_PORT,
    database: process.env.DB_NAME,
    user:     process.env.DB_USER,
    password: process.env.DB_PASSWORD,
});

// 연결 확인
pool.connect((err, client, release) => {
    if (err) {
        console.error('[DB] PostgreSQL 연결 실패:', err.message);
    } else {
        console.log('[DB] PostgreSQL 연결 성공');
        release();
    }
});

module.exports = pool;
