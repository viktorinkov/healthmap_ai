const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { runQuery, getOne } = require('../config/database');
const { authMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

// Register new user
router.post('/register',
  [
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 6 }),
    body('name').optional().trim()
  ],
  async (req, res, next) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, password, name } = req.body;

      // Check if user already exists
      const existingUser = await getOne('SELECT id FROM users WHERE email = ?', [email]);
      if (existingUser) {
        return res.status(409).json({ error: 'User already exists' });
      }

      // Hash password
      const hashedPassword = await bcrypt.hash(password, 10);

      // Create user
      const result = await runQuery(
        'INSERT INTO users (email, password, name) VALUES (?, ?, ?)',
        [email, hashedPassword, name]
      );

      // Generate token
      const token = jwt.sign(
        { userId: result.id, email },
        process.env.JWT_SECRET,
        { expiresIn: '30d' }
      );

      // Create session
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 30);

      await runQuery(
        'INSERT INTO sessions (user_id, token, expires_at) VALUES (?, ?, ?)',
        [result.id, token, expiresAt.toISOString()]
      );

      res.status(201).json({
        message: 'User created successfully',
        user: {
          id: result.id,
          email,
          name
        },
        token
      });
    } catch (error) {
      next(error);
    }
  }
);

// Login
router.post('/login',
  [
    body('email').isEmail().normalizeEmail(),
    body('password').notEmpty()
  ],
  async (req, res, next) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, password } = req.body;

      // Find user
      const user = await getOne(
        'SELECT id, email, name, password FROM users WHERE email = ?',
        [email]
      );

      if (!user) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      // Verify password
      const isPasswordValid = await bcrypt.compare(password, user.password);
      if (!isPasswordValid) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      // Generate token
      const token = jwt.sign(
        { userId: user.id, email: user.email },
        process.env.JWT_SECRET,
        { expiresIn: '30d' }
      );

      // Create session
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 30);

      await runQuery(
        'INSERT INTO sessions (user_id, token, expires_at) VALUES (?, ?, ?)',
        [user.id, token, expiresAt.toISOString()]
      );

      res.json({
        message: 'Login successful',
        user: {
          id: user.id,
          email: user.email,
          name: user.name
        },
        token
      });
    } catch (error) {
      next(error);
    }
  }
);

// Logout
router.post('/logout', authMiddleware, async (req, res, next) => {
  try {
    // Delete session
    await runQuery('DELETE FROM sessions WHERE token = ?', [req.token]);

    res.json({ message: 'Logout successful' });
  } catch (error) {
    next(error);
  }
});

// Verify token
router.get('/verify', authMiddleware, async (req, res) => {
  res.json({
    valid: true,
    user: req.user
  });
});

// Refresh token
router.post('/refresh', authMiddleware, async (req, res, next) => {
  try {
    // Delete old session
    await runQuery('DELETE FROM sessions WHERE token = ?', [req.token]);

    // Generate new token
    const newToken = jwt.sign(
      { userId: req.user.id, email: req.user.email },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    // Create new session
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30);

    await runQuery(
      'INSERT INTO sessions (user_id, token, expires_at) VALUES (?, ?, ?)',
      [req.user.id, newToken, expiresAt.toISOString()]
    );

    res.json({
      message: 'Token refreshed successfully',
      token: newToken
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;