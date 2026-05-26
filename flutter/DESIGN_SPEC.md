# PlantDoc Design Specification

## App Overview
PlantDoc is an AI-powered plant disease detection app designed for Nepali farmers. Users can scan plant leaves using their phone camera and receive instant AI diagnosis of plant diseases with treatment recommendations.

---

## Design System

### Color Palette

| Name | Hex | Usage |
|------|-----|-------|
| Background | `#0D1F17` | Main app background |
| Card | `#142920` | Card backgrounds |
| Card Elevated | `#1A352A` | Elevated/hover card states |
| Primary (Lime) | `#A3E635` | CTA buttons, active states, accents |
| Emerald | `#34D399` | Healthy status, success states |
| Coral | `#F87171` | Diseased status, error states |
| Amber | `#FBBF24` | Warning status, medium risk |
| Indigo | `#818CF8` | Info, scan count indicators |
| Foreground | `#F1F5F9` | Primary text |
| Muted | `#64748B` | Secondary text, labels |

### Typography

- **Font Family**: Inter (Google Fonts)
- **Display**: 40px Bold - Welcome headings
- **Headline Large**: 24px Semi-bold - Section titles
- **Headline Medium**: 20px Semi-bold - Card titles
- **Title Large**: 16px Semi-bold - List item titles
- **Body Medium**: 14px Regular - Body text
- **Label Small**: 10px Medium - Badges, timestamps

### Spacing Scale

- `4px` - Tight spacing (between icons and labels)
- `8px` - Compact (chip padding, small gaps)
- `12px` - Default (card internal spacing)
- `16px` - Standard (section gaps)
- `20px` - Large (page padding)
- `24px` - Section separation
- `32px` - Major section breaks

### Border Radius

- `8px` - Small elements (icons, badges)
- `12px` - Buttons, inputs
- `16px` - Cards, containers
- `20px` - Large cards, chips
- `32px` - Bottom nav bar
- `50%` - Circular elements (avatars, indicators)

---

## Background Image

All screens **except the Home Screen** use a tea plantation background image for visual consistency.

**Image Source:**
- URL: `https://hebbkx1anhila5yf.public.blob.vercel-storage.com/bg-izlgJrgJ4er4k45FLPwZjiBi07hMkF.jpg`
- Local path (for production): `assets/images/bg.jpg`

**Implementation:**
- Use the `PageBackground` widget from `core/widgets/page_background.dart`
- Default overlay opacity: 0.7 (70% of AppColors.background)
- The overlay ensures text readability while showing the scenic background

**Usage:**
```dart
// In your screen's build method
return Scaffold(
  backgroundColor: AppColors.background,
  body: Stack(
    children: [
      const PageBackground(overlayOpacity: 0.7),
      // Your content here...
    ],
  ),
);
```

**Screens using this background:**
- Welcome Screen (with custom gradient overlay)
- Scan Result Screen
- Plant Tracker Screen
- History Screen

**Home Screen:** Uses its own hero image/gradient at the top (280px) - does NOT use PageBackground

---

## Component Patterns

### Glass Card
```
- Background: rgba(255, 255, 255, 0.05)
- Border: 1px solid rgba(255, 255, 255, 0.1)
- Blur: 10px backdrop-filter
- Border Radius: 16px
- Padding: 16px
```

### Stat Badge (Pill)
```
- Background: Card color (#142920)
- Border: 1px solid border color
- Border Radius: 20px
- Padding: 8px 12px
- Left: 28x28 icon container with accent/20% opacity
- Right: Value (bold) + Label (muted) stacked
```

### Bottom Navigation
```
- Container: Card color, border-radius 32px
- Height: 64px
- Floating above with 20px side margins, 24px bottom
- 4 nav items + center floating scan button
- Scan button: Lime (#A3E635), elevated -20px from bar top
- Shadow: 0 4px 20px rgba(0,0,0,0.3)
```

### Quick Action Card
```
- Glass card styling
- Top-left: 48x48 icon container with accent/20% bg
- Title: 16px semi-bold
- Subtitle: 12px muted
- Tap state: Slightly elevated background
```

---

## Screen Specifications

### 1. Welcome Screen (`/welcome`)

**Layout:**
- Full-screen background image (rice paddies/fields)
- Gradient overlay: transparent → 50% black → 95% background
- Stats pills row at top (accuracy, diseases, crops)
- Location badge with pin icon
- Large "WELCOME TO PLANTDOC" text
- Feature carousel (3 items: Instant Scan, Smart AI, Track Health)
- Bottom button row (back, eco icon, Get Started, skip)

**Background:** Aerial view of green rice terraces with golden hour lighting

### 2. Home Screen (`/home`)

**Layout:**
1. **Hero Section** (top 280px)
   - Background image with gradient overlay
   - Header: Avatar, greeting, notification bell
   - Welcome text: "How are your crops today?"
   - Location badge

2. **Stats Row** (horizontal scroll)
   - Total Scans (indigo)
   - Healthy count (emerald)
   - Diseased count (coral)

3. **Crop Filter** (horizontal chips)
   - All, Rice, Tomato, Potato, Wheat, Corn
   - Selected: Primary fill, others: Card fill

4. **Quick Actions** (2-column grid)
   - Scan Leaf (emerald accent)
   - My Plants (indigo accent)

5. **My Plants Section**
   - Horizontal scroll of plant cards
   - Each card: Icon, name, crop type, health percentage

6. **Recent Activity**
   - List of scan results with confidence scores

### 3. Scan Result Screen (`/result`)

**Layout:**
1. **Header** - Back button, "Scan Result" title, more options

2. **Plant Visualization** (top half)
   - Green gradient background
   - Hexagonal AI pattern overlay (subtle)
   - Center: Scanned plant image
   - Detection markers: Bug, bacterial, water icons
   - Animated scanning rings

3. **Bottom Panel** (rounded top corners)
   - "Rescan Your Plant" button
   - Disease cards (2-column): Bug Infected, Bacterial Blight
   - Progress bars for each disease
   - "Analyze & Get AI Recommendations" CTA
   - Confidence breakdown bars

### 4. Plant Tracker Screen (`/tracker`)

**Layout:**
1. **Header** - Back, "Potato Crop Overview", more

2. **Plant Selector** - Horizontal chips

3. **Growth Rate Card**
   - Title: "Growth Rate" + date range
   - Legend: Plant Height indicator
   - Bar chart: 7 bars showing growth over 90 days
   - X-axis: Days since planting

4. **Health Timeline Card**
   - Left: Days info, "Potato Crop Health Timeline" title
   - Right: Circular progress ring with days countdown

5. **Stats Grid** (2-column)
   - Water Depth: 50%
   - Plant Health: 80%

6. **Stage Progress**
   - 4-step indicator: Seeding → Sprout → Maturity → Harvest

### 5. History Screen (`/history`)

**Layout:**
1. **Header** with search bar
2. **Weekly Scans Chart** - Bar chart showing scans per day
3. **Quick Stats** - 2x2 grid (Total, Healthy, Diseased, Accuracy)
4. **Filter Chips** - All, Healthy, Diseased
5. **Scan List** - Cards with disease name, date, confidence

---

## Animation Guidelines

- **Page transitions**: Slide from right (300ms, ease-out)
- **Card press**: Scale to 0.98 (100ms)
- **Scan rings**: Continuous pulse outward (2s loop)
- **Progress bars**: Animate on appear (500ms, ease-out)
- **Number counting**: Animate from 0 to value (400ms)

---

## Iconography

Use Lucide or Material Icons:
- Home: `home`
- Scan: `document_scanner` or `camera`
- History: `history`
- Plants: `eco` or `leaf`
- Healthy: `check_circle`
- Diseased: `warning`
- Location: `location_on`
- Notification: `notifications`

---

## Prompt Templates for Cursor

### Creating a new screen:
```
Create a Flutter screen for [SCREEN NAME] matching the PlantDoc design system.
Use these colors: Background #0D1F17, Card #142920, Primary #A3E635
Follow the glass card pattern with backdrop blur.
Reference: [describe layout from this spec]
```

### Creating a widget:
```
Create a reusable [WIDGET NAME] widget for PlantDoc.
Style: Glassmorphism with 10px blur, white/5% background, white/10% border
Colors from AppColors class.
```

### Updating existing code:
```
Update [FILE] to match the PlantDoc design:
- Change background to #0D1F17
- Use Inter font family
- Apply glass card styling to containers
- Use emerald (#34D399) for healthy, coral (#F87171) for diseased
```

---

## File Structure
```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart      ✅ Created
│   │   ├── app_text_styles.dart ✅ Created
│   │   └── app_theme.dart       ✅ Created
│   └── widgets/
│       ├── glass_card.dart      ✅ Created
│       ├── bottom_nav.dart      ✅ Created
│       ├── stat_widgets.dart    ✅ Created
│       ├── progress_widgets.dart ✅ Created
│       └── page_background.dart ✅ Created (NEW)
├── screens/
│   ├── welcome_screen.dart      ✅ Created
│   ├── home_screen.dart         ✅ Created
│   ├── scan_result_screen.dart  ✅ Created
│   ├── plant_tracker_screen.dart ✅ Created
│   └── history_screen.dart      ✅ Created (NEW)
├── features/
│   ├── welcome/
│   ├── home/
│   ├── scan/
│   ├── result/
│   ├── history/
│   └── tracker/
└── main.dart                    ✅ Created
```
