#!/bin/bash

# Health Map AI Backend Optimization Script
# This script handles performance optimization and cache cleaning

echo "🚀 Starting Health Map AI Backend Optimization..."

# Set the backend directory
BACKEND_DIR="/Users/chanyeong/Desktop/development/healthmap_ai/backend_python"
FLUTTER_DIR="/Users/chanyeong/Desktop/development/healthmap_ai"

# Change to backend directory
cd "$BACKEND_DIR" || exit 1

# Step 1: Clean Flutter cache if requested
echo "🧹 Cleaning Flutter cache..."
cd "$FLUTTER_DIR" || exit 1

# Clean Flutter build cache
flutter clean

# Clear Flutter pub cache (optional - uncomment if needed)
# flutter pub cache clean

# Clear Flutter engine cache
# rm -rf ~/.flutter
# flutter precache

echo "✅ Flutter cache cleaned"

# Step 2: Optimize Python backend
echo "🐍 Setting up Python backend..."
cd "$BACKEND_DIR" || exit 1

# Install optimized requirements
pip install -r requirements_optimized.txt

# Step 3: Set memory limits and environment variables
echo "⚙️ Setting environment variables for optimal performance..."

# Memory optimization environment variables
export PYTHONOPTIMIZE=1
export PYTHONUNBUFFERED=1
export PYTHONDONTWRITEBYTECODE=1

# PostgreSQL connection optimization
export PGCONNECT_TIMEOUT=10
export PGCOMMAND_TIMEOUT=30

# Flask optimization
export FLASK_ENV=production
export FLASK_DEBUG=False

# Step 4: Database optimization
echo "🗄️ Optimizing database connections..."

# Check if PostgreSQL is running
if ! pgrep -x "postgres" > /dev/null; then
    echo "⚠️ PostgreSQL is not running. Please start PostgreSQL service."
    echo "On macOS: brew services start postgresql"
    exit 1
fi

# Step 5: Set memory limits for the Python process
echo "💾 Setting memory limits..."

# Set Python memory limit (adjust as needed - 1GB limit)
ulimit -v 1048576

# Step 6: Start the optimized application
echo "🚀 Starting optimized Health Map AI backend..."

# Run with optimized settings
python3 -OO app.py

echo "✅ Backend optimization complete!"