const express = require('express');
const pool = require('../db/postgres');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

const VALID_CATEGORIES = ['자유', '질문', '공략', '전체'];
const PAGE_SIZE = 20;

// ──────────────────────────────────────────
// GET /api/community/posts?category=전체&page=1
// ──────────────────────────────────────────
router.get('/posts', async (req, res) => {
    const category = req.query.category || '전체';
    const page     = Math.max(1, parseInt(req.query.page) || 1);
    const offset   = (page - 1) * PAGE_SIZE;

    try {
        const listWhereClause = category === '전체'
            ? ''
            : 'WHERE p.category = $3';
        const countWhereClause = category === '전체'
            ? ''
            : 'WHERE p.category = $1';

        const listParams = category === '전체'
            ? [PAGE_SIZE, offset]
            : [PAGE_SIZE, offset, category];
        const countParams = category === '전체' ? [] : [category];

        const result = await pool.query(
            `SELECT p.id, p.title, p.category, p.view_count,
                    p.created_at, u.user_id AS author_id, u.nickname AS author_nickname,
                    (SELECT COUNT(*) FROM comments c WHERE c.post_id = p.id) AS comment_count
             FROM posts p
             JOIN users u ON u.id = p.author_id
             ${listWhereClause}
             ORDER BY p.created_at DESC
             LIMIT $1 OFFSET $2`,
            listParams
        );

        const countResult = await pool.query(
            `SELECT COUNT(*) FROM posts p ${countWhereClause}`,
            countParams
        );

        return res.json({
            posts:      result.rows,
            total:      parseInt(countResult.rows[0].count),
            page,
            pageSize:   PAGE_SIZE,
        });
    } catch (err) {
        console.error('[Community] 게시글 목록 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// ──────────────────────────────────────────
// POST /api/community/posts  (인증 필요)
// body: { title, content, category }
// ──────────────────────────────────────────
router.post('/posts', authMiddleware, async (req, res) => {
    const { title, content, category = '자유' } = req.body;

    if (!title || !content)
        return res.status(400).json({ message: '제목과 내용을 입력해주세요.' });

    if (title.length > 100)
        return res.status(400).json({ message: '제목은 100자 이하여야 합니다.' });

    if (!VALID_CATEGORIES.includes(category))
        return res.status(400).json({ message: `카테고리는 ${VALID_CATEGORIES.slice(0, 3).join(', ')} 중 하나여야 합니다.` });

    try {
        const userResult = await pool.query(
            'SELECT id FROM users WHERE user_id = $1',
            [req.user.userId]
        );
        if (userResult.rows.length === 0)
            return res.status(404).json({ message: '유저를 찾을 수 없습니다.' });

        const authorId = userResult.rows[0].id;

        const result = await pool.query(
            `INSERT INTO posts (title, content, category, author_id)
             VALUES ($1, $2, $3, $4)
             RETURNING id, title, content, category, view_count, created_at`,
            [title, content, category, authorId]
        );

        const post = result.rows[0];
        return res.status(201).json({
            message: '게시글 작성 성공',
            post: {
                ...post,
                authorId:       req.user.userId,
                authorNickname: req.user.nickname,
            },
        });
    } catch (err) {
        console.error('[Community] 게시글 작성 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// ──────────────────────────────────────────
// GET /api/community/posts/:postId  (조회수 +1 포함)
// ──────────────────────────────────────────
router.get('/posts/:postId', async (req, res) => {
    const postId = parseInt(req.params.postId);
    if (isNaN(postId))
        return res.status(400).json({ message: '잘못된 게시글 ID입니다.' });

    try {
        const result = await pool.query(
            `UPDATE posts SET view_count = view_count + 1
             WHERE id = $1
             RETURNING id, title, content, category, view_count, created_at, updated_at, author_id`,
            [postId]
        );

        if (result.rows.length === 0)
            return res.status(404).json({ message: '게시글을 찾을 수 없습니다.' });

        const post = result.rows[0];

        const authorResult = await pool.query(
            'SELECT user_id, nickname FROM users WHERE id = $1',
            [post.author_id]
        );
        const author = authorResult.rows[0];

        return res.json({
            id:             post.id,
            title:          post.title,
            content:        post.content,
            category:       post.category,
            viewCount:      post.view_count,
            createdAt:      post.created_at,
            updatedAt:      post.updated_at,
            authorId:       author.user_id,
            authorNickname: author.nickname,
        });
    } catch (err) {
        console.error('[Community] 게시글 상세 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// ──────────────────────────────────────────
// GET /api/community/posts/:postId/comments
// ──────────────────────────────────────────
router.get('/posts/:postId/comments', async (req, res) => {
    const postId = parseInt(req.params.postId);
    if (isNaN(postId))
        return res.status(400).json({ message: '잘못된 게시글 ID입니다.' });

    try {
        const result = await pool.query(
            `SELECT c.id, c.content, c.created_at,
                    u.user_id AS author_id, u.nickname AS author_nickname
             FROM comments c
             JOIN users u ON u.id = c.author_id
             WHERE c.post_id = $1
             ORDER BY c.created_at ASC`,
            [postId]
        );

        return res.json({ comments: result.rows });
    } catch (err) {
        console.error('[Community] 댓글 목록 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// ──────────────────────────────────────────
// POST /api/community/posts/:postId/comments  (인증 필요)
// body: { content }
// ──────────────────────────────────────────
router.post('/posts/:postId/comments', authMiddleware, async (req, res) => {
    const postId  = parseInt(req.params.postId);
    const { content } = req.body;

    if (isNaN(postId))
        return res.status(400).json({ message: '잘못된 게시글 ID입니다.' });

    if (!content)
        return res.status(400).json({ message: '댓글 내용을 입력해주세요.' });

    try {
        const postExists = await pool.query('SELECT id FROM posts WHERE id = $1', [postId]);
        if (postExists.rows.length === 0)
            return res.status(404).json({ message: '게시글을 찾을 수 없습니다.' });

        const userResult = await pool.query(
            'SELECT id FROM users WHERE user_id = $1',
            [req.user.userId]
        );
        const authorId = userResult.rows[0].id;

        const result = await pool.query(
            `INSERT INTO comments (post_id, content, author_id)
             VALUES ($1, $2, $3)
             RETURNING id, content, created_at`,
            [postId, content, authorId]
        );

        const comment = result.rows[0];
        return res.status(201).json({
            message: '댓글 작성 성공',
            comment: {
                ...comment,
                authorId:       req.user.userId,
                authorNickname: req.user.nickname,
            },
        });
    } catch (err) {
        console.error('[Community] 댓글 작성 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// ──────────────────────────────────────────
// PATCH /api/community/posts/:postId  (인증 필요, 본인 글만)
// body: { title?, content?, category? }
// ──────────────────────────────────────────
router.patch('/posts/:postId', authMiddleware, async (req, res) => {
    const postId = parseInt(req.params.postId);
    if (isNaN(postId))
        return res.status(400).json({ message: '잘못된 게시글 ID입니다.' });

    const { title, content, category } = req.body;

    if (title === undefined && content === undefined && category === undefined)
        return res.status(400).json({ message: '수정할 내용을 입력해주세요.' });

    if (title !== undefined && (title.length === 0 || title.length > 100))
        return res.status(400).json({ message: '제목은 1자 이상 100자 이하여야 합니다.' });

    if (category !== undefined && !VALID_CATEGORIES.includes(category))
        return res.status(400).json({ message: `카테고리는 ${VALID_CATEGORIES.slice(0, 3).join(', ')} 중 하나여야 합니다.` });

    try {
        const postResult = await pool.query(
            'SELECT author_id FROM posts WHERE id = $1',
            [postId]
        );
        if (postResult.rows.length === 0)
            return res.status(404).json({ message: '게시글을 찾을 수 없습니다.' });

        const userResult = await pool.query(
            'SELECT id FROM users WHERE user_id = $1',
            [req.user.userId]
        );
        if (userResult.rows.length === 0)
            return res.status(404).json({ message: '유저를 찾을 수 없습니다.' });

        // 본인 글만 수정 가능
        if (postResult.rows[0].author_id !== userResult.rows[0].id)
            return res.status(403).json({ message: '본인이 작성한 게시글만 수정할 수 있습니다.' });

        // 전달된 필드만 부분 수정 (COALESCE)
        const result = await pool.query(
            `UPDATE posts
                SET title    = COALESCE($1, title),
                    content  = COALESCE($2, content),
                    category = COALESCE($3, category),
                    updated_at = NOW()
              WHERE id = $4
              RETURNING id, title, content, category, view_count, created_at, updated_at`,
            [title ?? null, content ?? null, category ?? null, postId]
        );

        return res.json({ message: '게시글 수정 성공', post: result.rows[0] });
    } catch (err) {
        console.error('[Community] 게시글 수정 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// ──────────────────────────────────────────
// DELETE /api/community/posts/:postId  (인증 필요, 본인 글만)
// 연관 댓글은 FK ON DELETE CASCADE로 함께 삭제됨
// ──────────────────────────────────────────
router.delete('/posts/:postId', authMiddleware, async (req, res) => {
    const postId = parseInt(req.params.postId);
    if (isNaN(postId))
        return res.status(400).json({ message: '잘못된 게시글 ID입니다.' });

    try {
        const postResult = await pool.query(
            'SELECT author_id FROM posts WHERE id = $1',
            [postId]
        );
        if (postResult.rows.length === 0)
            return res.status(404).json({ message: '게시글을 찾을 수 없습니다.' });

        const userResult = await pool.query(
            'SELECT id FROM users WHERE user_id = $1',
            [req.user.userId]
        );
        if (userResult.rows.length === 0)
            return res.status(404).json({ message: '유저를 찾을 수 없습니다.' });

        if (postResult.rows[0].author_id !== userResult.rows[0].id)
            return res.status(403).json({ message: '본인이 작성한 게시글만 삭제할 수 있습니다.' });

        await pool.query('DELETE FROM posts WHERE id = $1', [postId]);

        return res.json({ message: '게시글 삭제 성공' });
    } catch (err) {
        console.error('[Community] 게시글 삭제 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

// ──────────────────────────────────────────
// DELETE /api/community/comments/:commentId  (인증 필요, 본인 댓글만)
// ──────────────────────────────────────────
router.delete('/comments/:commentId', authMiddleware, async (req, res) => {
    const commentId = parseInt(req.params.commentId);
    if (isNaN(commentId))
        return res.status(400).json({ message: '잘못된 댓글 ID입니다.' });

    try {
        const commentResult = await pool.query(
            'SELECT author_id FROM comments WHERE id = $1',
            [commentId]
        );
        if (commentResult.rows.length === 0)
            return res.status(404).json({ message: '댓글을 찾을 수 없습니다.' });

        const userResult = await pool.query(
            'SELECT id FROM users WHERE user_id = $1',
            [req.user.userId]
        );
        if (userResult.rows.length === 0)
            return res.status(404).json({ message: '유저를 찾을 수 없습니다.' });

        if (commentResult.rows[0].author_id !== userResult.rows[0].id)
            return res.status(403).json({ message: '본인이 작성한 댓글만 삭제할 수 있습니다.' });

        await pool.query('DELETE FROM comments WHERE id = $1', [commentId]);

        return res.json({ message: '댓글 삭제 성공' });
    } catch (err) {
        console.error('[Community] 댓글 삭제 오류:', err.message);
        return res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
});

module.exports = router;
