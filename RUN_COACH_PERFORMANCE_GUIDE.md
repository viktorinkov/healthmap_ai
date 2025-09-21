# Run Coach Performance Optimization Guide

## Current Performance Optimizations

### 1. Backend Optimizations
- **Caching**: Implemented 5-minute cache for pollution heatmap data
- **Resolution**: Reduced pollution grid from 100m to 200m resolution
- **Lazy Loading**: Services initialized only when needed

### 2. Flutter App Optimizations
- **Tile Caching**: Limited to 50 tiles to prevent memory issues
- **Zoom Restrictions**: Only render heatmap tiles between zoom levels 10-16
- **Transparent Tiles**: Return empty tiles outside optimal zoom range

### 3. Quick Performance Fixes

If the Run Coach is still slow, try these:

#### Option 1: Disable Heatmap Overlay (Quickest)
In `run_coach_map_screen.dart`, comment out the tile overlay:
```dart
// tileOverlays.add(
//   TileOverlay(
//     tileOverlayId: const TileOverlayId('run_coach_air_quality_heatmap'),
//     tileProvider: RunCoachHeatmapTileProvider(),
//     transparency: 0.3,
//     fadeIn: true,
//   ),
// );
```

#### Option 2: Use Static Markers Instead
Replace dynamic heatmap with static pollution zone markers for key areas.

#### Option 3: Pre-compute Routes
Cache common routes from popular locations to reduce computation time.

### 4. Android Emulator Performance Tips

1. **Enable Hardware Acceleration**:
   - In AVD Manager → Edit → Graphics: Hardware - GLES 2.0

2. **Increase RAM**:
   - AVD Manager → Edit → Advanced Settings → RAM: 4096 MB

3. **Use x86 Images** (if available):
   - Better performance than ARM images on Intel/AMD processors

4. **Enable GPU Host**:
   ```bash
   $ANDROID_HOME/emulator/emulator -avd Medium_Phone_API_36.1 -gpu host
   ```

### 5. Testing Performance

Run these commands to monitor performance:

```bash
# Check backend response times
time curl "http://localhost:5001/api/run-coach/pollution-heatmap?lat=29.7174&lon=-95.4018&radius_km=5"

# Monitor Flutter performance
flutter run --profile

# Check memory usage
adb shell dumpsys meminfo com.healthmap.healthmap_ai
```

### 6. Demo Mode for Hackathon

For the hackathon demo, consider:

1. **Pre-load Data**: Cache pollution data before demo
2. **Limit Features**: Disable real-time updates during demo
3. **Use Smaller Radius**: Reduce default radius from 10km to 5km
4. **Offline Mode**: Use pre-computed routes if network is slow

### 7. Real Device Testing

For best performance during demo:
```bash
# Connect real Android device via USB
adb devices
flutter run --release
```

### 8. Emergency Fallback

If performance issues persist during demo:
1. Use the static visualization files (PNG/HTML)
2. Show pre-recorded demo video
3. Focus on algorithm explanation rather than live demo