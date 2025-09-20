#!/bin/bash
# Performance Fix Script for HealthMap AI Run Coach

echo "🔧 Applying Performance Fixes..."

# 1. Clear Flutter cache
echo "1️⃣ Clearing Flutter cache..."
flutter clean
flutter pub cache clean --force
flutter pub get

# 2. Clear Android build cache
echo "2️⃣ Clearing Android build cache..."
cd android
./gradlew clean
cd ..

# 3. Clear emulator cache
echo "3️⃣ Clearing emulator data..."
adb shell pm clear com.healthmap.healthmap_ai || true

# 4. Set environment variables for demo mode
echo "4️⃣ Setting demo mode environment..."
export DEMO_MODE=true
export FLASK_ENV=production
export PYTHONUNBUFFERED=1

# 5. Start backend with limited resources
echo "5️⃣ Starting optimized backend..."
echo "Run this command in a separate terminal:"
echo "ulimit -m 1048576 && python backend_python/app.py"

echo ""
echo "✅ Performance fixes applied!"
echo ""
echo "Next steps:"
echo "1. Start backend: python backend_python/app.py"
echo "2. Run Flutter: flutter run --release"
echo ""
echo "If still slow, try:"
echo "- Use a real Android device instead of emulator"
echo "- Run: flutter run --release --no-sound-null-safety"