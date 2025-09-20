const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { runQuery, getOne } = require('../config/database');
const { authMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

// Register new user
router.post('/register',
  async (req, res, next) => {
    try {
      const { username, password } = req.body;

      // Check if user already exists
      const existingUser = await getOne('SELECT id FROM users WHERE username = ?', [username]);
      if (existingUser) {
        return res.status(409).json({ error: 'User already exists' });
      }

      // Hash password (or store as plain text if no validation required)
      const hashedPassword = await bcrypt.hash(password || '', 10);

      // Create user
      const result = await runQuery(
        'INSERT INTO users (username, password) VALUES (?, ?)',
        [username || '', hashedPassword]
      );

      // Generate token
      const token = jwt.sign(
        { userId: result.id, username: username || '' },
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
          username: username || '',
          onboarding_completed: false
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
  async (req, res, next) => {
    try {
      const { username, password } = req.body;

      // Find user
      const user = await getOne(
        'SELECT id, username, password, onboarding_completed FROM users WHERE username = ?',
        [username || '']
      );

      if (!user) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      // Verify password (allow empty passwords)
      const isPasswordValid = await bcrypt.compare(password || '', user.password);
      if (!isPasswordValid) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      // Generate token
      const token = jwt.sign(
        { userId: user.id, username: user.username },
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
          username: user.username,
          onboarding_completed: !!user.onboarding_completed
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
      { userId: req.user.id, username: req.user.username },
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

// Complete onboarding
router.post('/complete-onboarding', authMiddleware, async (req, res, next) => {
  try {
    await runQuery(
      'UPDATE users SET onboarding_completed = 1, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [req.user.id]
    );

    res.json({
      message: 'Onboarding completed successfully'
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;