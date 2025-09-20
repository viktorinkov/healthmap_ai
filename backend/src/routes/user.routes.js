const express = require('express');
const { body, validationResult } = require('express-validator');
const { runQuery, getOne, getAll } = require('../config/database');
const { authMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

// Get user profile
router.get('/profile', authMiddleware, async (req, res, next) => {
  try {
    const user = await getOne(
      'SELECT id, username, created_at, onboarding_completed FROM users WHERE id = ?',
      [req.user.id]
    );

    const medicalProfile = await getOne(
      'SELECT * FROM medical_profiles WHERE user_id = ?',
      [req.user.id]
    );

    res.json({
      user,
      medicalProfile
    });
  } catch (error) {
    next(error);
  }
});

// Update user profile
router.put('/profile',
  authMiddleware,
  async (req, res, next) => {
    try {
      const { username } = req.body;
      const updates = [];
      const params = [];

      if (username !== undefined) {
        updates.push('username = ?');
        params.push(username);
      }

      if (updates.length > 0) {
        updates.push('updated_at = CURRENT_TIMESTAMP');
        params.push(req.user.id);

        await runQuery(
          `UPDATE users SET ${updates.join(', ')} WHERE id = ?`,
          params
        );
      }

      res.json({ message: 'Profile updated successfully' });
    } catch (error) {
      next(error);
    }
  }
);

// Get medical profile
router.get('/medical-profile', authMiddleware, async (req, res, next) => {
  try {
    const profile = await getOne(
      'SELECT * FROM medical_profiles WHERE user_id = ?',
      [req.user.id]
    );

    if (!profile) {
      return res.status(404).json({ error: 'Medical profile not found' });
    }

    res.json(profile);
  } catch (error) {
    next(error);
  }
});

// Create or update medical profile
router.post('/medical-profile',
  authMiddleware,
  async (req, res, next) => {
    try {

      const existingProfile = await getOne(
        'SELECT id FROM medical_profiles WHERE user_id = ?',
        [req.user.id]
      );

      const data = {
        age: req.body.age,
        has_respiratory_condition: req.body.has_respiratory_condition ? 1 : 0,
        has_heart_condition: req.body.has_heart_condition ? 1 : 0,
        has_allergies: req.body.has_allergies ? 1 : 0,
        is_elderly: req.body.is_elderly ? 1 : 0,
        is_child: req.body.is_child ? 1 : 0,
        is_pregnant: req.body.is_pregnant ? 1 : 0,
        exercises_outdoors: req.body.exercises_outdoors ? 1 : 0,
        medications: req.body.medications,
        notes: req.body.notes
      };

      if (existingProfile) {
        // Update existing profile
        const updates = [];
        const params = [];

        Object.entries(data).forEach(([key, value]) => {
          if (value !== undefined) {
            updates.push(`${key} = ?`);
            params.push(value);
          }
        });

        if (updates.length > 0) {
          updates.push('updated_at = CURRENT_TIMESTAMP');
          params.push(req.user.id);

          await runQuery(
            `UPDATE medical_profiles SET ${updates.join(', ')} WHERE user_id = ?`,
            params
          );
        }

        res.json({ message: 'Medical profile updated successfully' });
      } else {
        // Create new profile
        const columns = ['user_id'];
        const values = [req.user.id];
        const placeholders = ['?'];

        Object.entries(data).forEach(([key, value]) => {
          if (value !== undefined) {
            columns.push(key);
            values.push(value);
            placeholders.push('?');
          }
        });

        await runQuery(
          `INSERT INTO medical_profiles (${columns.join(', ')}) VALUES (${placeholders.join(', ')})`,
          values
        );

        res.status(201).json({ message: 'Medical profile created successfully' });
      }
    } catch (error) {
      next(error);
    }
  }
);

// Delete medical profile
router.delete('/medical-profile', authMiddleware, async (req, res, next) => {
  try {
    await runQuery(
      'DELETE FROM medical_profiles WHERE user_id = ?',
      [req.user.id]
    );

    res.json({ message: 'Medical profile deleted successfully' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;