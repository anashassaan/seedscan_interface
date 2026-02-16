# SeedScan AI Coding Instructions

## Project Overview
SeedScan is a Flutter mobile app for AI-powered tree plantation management with leaf disease detection using TensorFlow Lite models. The app combines QR code scanning for plant identification with ML-based disease diagnosis.

## Architecture & Code Organization

### Directory Structure Pattern
- `lib/config/`: App configuration including theme, assets, and MVC structure
  - `controllers/`: State management using Provider (ChangeNotifier pattern)
  - `views/`: UI screens organized by feature (auth, scan, social, profile, etc.)
- `lib/services/`: AI/ML services for TFLite model inference
- `lib/models/`: Data models (currently empty - in-memory state only)
- `lib/utils/`: Utility functions
- `assets/models/`: TFLite model files (`.tflite`)
- `assets/images/`: Image assets

### State Management Convention
All state is managed via Provider with ChangeNotifier controllers. Key controllers:
- `AuthController`: Mock authentication (in-memory, no backend)
- `ScanController`: Camera/QR scanning + location services
- `ChatController`: In-app messaging features
- `ThemeController`: Dark/light theme switching
- `NotificationController`: App notifications

**Pattern**: Controllers live in `lib/config/controllers/`, registered in `main.dart` as MultiProvider.

```dart
// Standard controller pattern
class MyController extends ChangeNotifier {
  void updateState() {
    // modify state
    notifyListeners();
  }
}
```

### Theme & Styling
- Material Design 3 with custom seed color: `#0B6E4F` (botanical green)
- Google Fonts (Inter) used throughout
- Theme configuration in [lib/config/theme.dart](lib/config/theme.dart)
- Rounded corners (16-18px) and consistent elevation (2-4)

## ML/AI Services Architecture

### Two-Stage Disease Detection Pipeline
Located in `lib/services/`:

1. **Apple Detection** ([apple_detection_service.dart](lib/services/apple_detection_service.dart)):
   - Binary classifier (Apple vs Non-Apple leaf)
   - Input: 224x224 grayscale image
   - Model: `apple_detector.tflite`

2. **Disease Diagnosis** ([leaf_diagnosis_service.dart](lib/services/leaf_diagnosis_service.dart)):
   - Two-stage: YOLOv8n detection → MobileNetV3 classification
   - **Critical preprocessing**: Gamma correction (γ=1.2), color enhancement
   - Detection thresholds: Primary 0.25, fallback 0.15
   - 9 disease classes including "Healthy"
   - Models: `best_float16.tflite` (YOLO), `mobilenetv3_apple_disease.tflite`

**Key configuration parameters** (from extensive accuracy tuning):
```dart
LeafDiagnosisService(
  detectionThreshold: 0.25,        // Balanced 25% threshold
  fallbackDetectionThreshold: 0.15, // Edge case detection
  enablePreprocessing: true,        // CRITICAL for accuracy
  interpreterThreads: 4,            // Mobile optimization
)
```

### TFLite Integration Pattern
- Use `tflite_flutter` package
- Models loaded via `Interpreter.fromAsset('models/...')`
- Singleton pattern with `_loaded` flag to prevent re-initialization
- Input normalization: Divide by 255.0 for [0,1] range

## Camera & Permissions

### Mobile Scanner Usage
- Package: `mobile_scanner` (dual QR + camera functionality)
- Controller in `ScanController` with `DetectionSpeed.noDuplicates`
- Toggle torch, switch cameras, and toggle between QR/disease modes
- Location services via `geolocator` + `permission_handler`

**Permission pattern**: Request before use, graceful degradation if denied.

## Authentication Flow
Mock authentication only - no backend integration:
- In-memory storage in `AuthController`
- Accepts any email with password ≥6 chars
- Entry point: `EntryDecider` widget switches between `LoginView` and `MainNavigation`

## Development Workflows

### Running the App
```bash
flutter run
# Or for specific device:
flutter run -d windows
flutter run -d android
```

### Building
```bash
flutter build apk          # Android APK
flutter build appbundle    # Android App Bundle
flutter build ios          # iOS (macOS only)
```

### Linting
- Uses `package:flutter_lints/flutter.yaml`
- Configuration in [analysis_options.yaml](analysis_options.yaml)
- Run: `flutter analyze`

### Asset Management
- Declare assets in `pubspec.yaml` under `flutter.assets`
- Current assets: `assets/images/`, `assets/models/`

## Key Dependencies
- **State**: `provider: ^6.0.5`
- **ML**: `tflite_flutter: ^0.11.0`
- **Camera**: `mobile_scanner: ^7.1.3`, `camera: ^0.10.5`, `image_picker: ^1.1.0`
- **Location**: `geolocator: ^10.1.0`, `permission_handler: ^11.0.1`
- **UI**: `google_fonts: ^5.0.0`, `lucide_icons: ^0.257.0`

## Critical Conventions

### File Naming
- Snake_case for files: `scan_controller.dart`, `unified_scan_screen.dart`
- PascalCase for classes: `ScanController`, `UnifiedScanScreen`

### Import Organization
1. Flutter/Dart SDK imports
2. Package imports
3. Relative imports (local project files)

### Widget Structure
- Prefer StatelessWidget for presentation
- StatefulWidget only when managing local UI state
- Use `const` constructors wherever possible for performance

### Error Handling in Services
- Services use try-catch with print statements for debugging
- Graceful fallbacks in ML services (multi-pass detection strategy)

## Common Gotchas

1. **TFLite models must be in `assets/models/`** and declared in pubspec.yaml
2. **Provider context**: Use `Provider.of<T>(context, listen: false)` for actions, `context.watch<T>()` for reactive UI
3. **Hot reload limitations**: Some plugin changes (camera, permissions) require hot restart
4. **FP16 models**: Faster but may have slight accuracy differences vs FP32
5. **Preprocessing is critical**: Disease detection accuracy heavily depends on gamma correction and color enhancement

## Testing
- Test file: `test/widget_test.dart` (currently minimal)
- Run: `flutter test`
