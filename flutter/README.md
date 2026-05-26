# PlantDoc Flutter Starter Kit

A complete Flutter UI kit for the PlantDoc plant disease detection app, matching the v0 web design.

## Quick Start

1. **Copy to your project**: Copy the contents of this folder to your Flutter project's `lib/` directory

2. **Update pubspec.yaml**: Merge the dependencies from `pubspec.yaml` into your project

3. **Install packages**:
   ```bash
   flutter pub get
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## Included Files

### Theme System
- `lib/core/theme/app_colors.dart` - Complete color palette
- `lib/core/theme/app_text_styles.dart` - Typography system
- `lib/core/theme/app_theme.dart` - Material theme configuration

### Reusable Widgets
- `lib/core/widgets/glass_card.dart` - Glassmorphism cards
- `lib/core/widgets/bottom_nav.dart` - Custom floating bottom navigation
- `lib/core/widgets/stat_widgets.dart` - Stat badges and cards
- `lib/core/widgets/progress_widgets.dart` - Circular progress, health scores

### Screen Templates
- `lib/screens/welcome_screen.dart` - Onboarding/welcome page
- `lib/screens/home_screen.dart` - Main dashboard
- `lib/screens/scan_result_screen.dart` - AI scan results
- `lib/screens/plant_tracker_screen.dart` - Plant growth tracking

### Documentation
- `DESIGN_SPEC.md` - Complete design specification for Cursor/Copilot

## Using with Cursor

1. Open your Flutter project in Cursor
2. Add the `DESIGN_SPEC.md` to your project root
3. Create a `.cursorrules` file:

```
You are a Flutter developer working on PlantDoc, a plant disease detection app.

Design System:
- Read DESIGN_SPEC.md for complete specifications
- Use AppColors from lib/core/theme/app_colors.dart
- Use AppTextStyles from lib/core/theme/app_text_styles.dart
- Use GlassCard widget for all card containers
- Follow mobile-first design (375px width reference)

Code Style:
- Use StatefulWidget for screens with user interaction
- Extract reusable widgets to core/widgets/
- Follow feature-based folder structure
- Use const constructors where possible
```

4. Reference the design spec in prompts:
   ```
   Looking at DESIGN_SPEC.md, create the History screen with a search bar,
   weekly scans bar chart, and a list of past scan results.
   ```

## Customization

### Adding your ML model

Replace the placeholder scan logic in `scan_result_screen.dart`:

```dart
// Import tflite_flutter
import 'package:tflite_flutter/tflite_flutter.dart';

// Load model
final interpreter = await Interpreter.fromAsset('model.tflite');

// Run inference
interpreter.run(inputImage, output);
```

### Connecting to backend

Add your API service in `lib/core/services/api_service.dart`:

```dart
class ApiService {
  static const baseUrl = 'https://your-api.com';
  
  Future<ScanResult> analyzePlant(File image) async {
    // Upload image and get results
  }
}
```

## Dependencies

Required packages (check pubspec.yaml for versions):
- `google_fonts` - Inter font family
- `fl_chart` - Charts and graphs
- `percent_indicator` - Circular progress indicators
- `flutter_animate` - Smooth animations
- `image_picker` - Camera/gallery access
- `camera` - Camera preview

## Screenshots

Reference the v0 preview at your project URL for visual reference.

## License

MIT - Use freely in your projects.
