function errorHandler(err, req, res, next) {
  console.error('Error:', err);

  // Handle validation errors
  if (err.type === 'validation') {
    return res.status(400).json({
      error: 'Validation error',
      details: err.errors
    });
  }

  // Handle database errors
  if (err.code === 'SQLITE_CONSTRAINT') {
    if (err.message.includes('UNIQUE')) {
      return res.status(409).json({
        error: 'Resource already exists'
      });
    }
    return res.status(400).json({
      error: 'Database constraint violated'
    });
  }

  // Handle JWT errors
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      error: 'Invalid token'
    });
  }

  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({
      error: 'Token expired'
    });
  }

  // Default error response
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal server error';

  res.status(statusCode).json({
    error: message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
}

module.exports = errorHandler;