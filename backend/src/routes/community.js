const express = require('express');
const { authMiddleware } = require('./auth');

const router = express.Router();

// GET /api/community/posts
router.get('/posts', (req, res) => {
    return res.json({
        message: '게시글 목록 조회 엔드포인트',
        category: req.query.category || '전체',
        posts: [],
    });
});

// POST /api/community/posts
router.post('/posts', authMiddleware, (req, res) => {
    return res.status(201).json({
        message: '게시글 작성 엔드포인트',
        body: req.body,
        user: req.user,
    });
});

// GET /api/community/posts/:postId
router.get('/posts/:postId', (req, res) => {
    return res.json({
        message: '게시글 상세 조회 엔드포인트',
        postId: req.params.postId,
        post: null,
    });
});

// POST /api/community/posts/:postId/view
router.post('/posts/:postId/view', (req, res) => {
    return res.json({
        message: '게시글 조회수 증가 엔드포인트',
        postId: req.params.postId,
        note: '세션 중복 조회 방지는 추후 구현',
    });
});

module.exports = router;