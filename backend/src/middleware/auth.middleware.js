const jwt = require('jsonwebtoken');
const { getOne } = require('../config/database');

async function authMiddleware(req, res, next) {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({ error: 'No authentication token provided' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Check if session exists and is not expired
    const session = await getOne(
      'SELECT * FROM sessions WHERE token = ? AND expires_at > datetime("now")',
      [token]
    );

    if (!session) {
      return res.status(401).json({ error: 'Invalid or expired session' });
    }

    const user = await getOne(
      'SELECT id, username FROM users WHERE id = ?',
      [decoded.userId]
    );

    if (!user) {
      return res.status(401).json({ error: 'User not found' });
    }

    req.user = user;
    req.token = token;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Invalid token' });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    console.error('Auth middleware error:', error);
    res.status(500).json({ error: 'Authentication failed' });
  }
}

// Optional auth middleware - doesn't require authentication but adds user if token is present
async function optionalAuth(req, res, next) {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      return next();
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await getOne(
      'SELECT id, username FROM users WHERE id = ?',
      [decoded.userId]
    );

    if (user) {
      req.user = user;
      req.token = token;
    }

    next();
  } catch (error) {
    // If token is invalid, just continue without user
    next();
  }
}

module.exports = {
  authMiddleware,
  optionalAuth
};