const express = require('express');

const router = express.Router();

// GET /api/ranking
router.get('/', (_req, res) => {
    return res.json({
        message: '랭킹 조회 엔드포인트',
        rankings: [],
    });
});

module.exports = router;