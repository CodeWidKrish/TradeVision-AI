# TradeVision AI — Design System
> Flutter / Dart · Light Mode Only · NSE & BSE · INR (₹)

---

## 1. Color Tokens

```dart
// lib/core/theme/app_colors.dart

class AppColors {
  // Brand
  static const primary        = Color(0xFF1B56F1); // Blue — CTA, cards, accents
  static const primaryLight   = Color(0xFFEFF4FF); // Blue tint — AI insight bg, chips

  // Semantic
  static const gain           = Color(0xFF16A34A); // Green — positive P&L, up %
  static const gainBg         = Color(0xFFDCFCE7); // Green tint — gain badges
  static const loss           = Color(0xFFDC2626); // Red — negative P&L, down %
  static const lossBg         = Color(0xFFFEE2E2); // Red tint — loss badges
  static const warning        = Color(0xFFF59E0B); // Amber — neutral/hold signals

  // Neutrals
  static const background     = Color(0xFFFFFFFF); // App background — pure white
  static const surface        = Color(0xFFF8F9FC); // Card/row background
  static const surfaceElevated= Color(0xFFFFFFFF); // Elevated card — with border
  static const border         = Color(0xFFE8E8E8); // Dividers, hairlines
  static const borderStrong   = Color(0xFFD0D0D0); // Input borders

  // Text
  static const textPrimary    = Color(0xFF1A1A1A); // Headings, prices, names
  static const textSecondary  = Color(0xFF666666); // Subtitles, labels
  static const textMuted      = Color(0xFF999999); // Captions, hints
  static const textOnPrimary  = Color(0xFFFFFFFF); // Text on blue backgrounds

  // Stock logo palette (for ticker avatars)
  static const logoReliance   = Color(0xFFFF6900);
  static const logoTCS        = Color(0xFF1B56F1);
  static const logoInfosys    = Color(0xFFF59E0B);
  static const logoHDFC       = Color(0xFF7C3AED);
  static const logoWipro      = Color(0xFF0891B2);
  static const logoSBI        = Color(0xFF16A34A);
}
```

---

## 2. Typography

```dart
// lib/core/theme/app_text_styles.dart
// Font: SF Pro Display (iOS) / Roboto (Android) via system font stack

class AppTextStyles {
  // Display
  static const portfolioValue = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700,
    letterSpacing: -0.5, color: AppColors.textOnPrimary,
  );
  static const chartPrice = TextStyle(
    fontSize: 30, fontWeight: FontWeight.w700,
    letterSpacing: -1.0, color: AppColors.textPrimary,
  );

  // Headings
  static const screenTitle = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const sectionTitle = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const cardTitle = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textOnPrimary,
  );

  // Body
  static const stockName = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const stockSubname = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textMuted,
  );
  static const stockPrice = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const bodyMedium = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
  );
  static const bodySmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
    height: 1.5,
  );

  // Labels / Captions
  static const label = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted,
  );
  static const labelUppercase = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary,
    letterSpacing: 0.5,
  );
  static const caption = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.textMuted,
  );

  // Change indicators
  static const changePositive = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gain,
  );
  static const changeNegative = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.loss,
  );
}
```

---

## 3. Spacing & Shape

```dart
// lib/core/theme/app_dimensions.dart

class AppDim {
  // Screen padding
  static const screenH  = 20.0; // horizontal screen padding
  static const screenV  = 16.0; // vertical section spacing

  // Radius
  static const radiusSm   = 8.0;
  static const radiusMd   = 12.0;
  static const radiusLg   = 14.0;
  static const radiusXl   = 20.0;
  static const radiusXxl  = 36.0; // phone outer frame
  static const radiusPill = 100.0;

  // Component sizes
  static const avatarSm     = 36.0;
  static const avatarMd     = 38.0;
  static const tickerLogo   = 36.0;
  static const tabBarHeight = 64.0;
  static const chipHeight   = 30.0;
  static const btnHeight    = 48.0;
  static const rowHeight    = 60.0;
  static const indexCardW   = 120.0;
  static const miniChartH   = 24.0;
}
```

---

## 4. Theme Config

```dart
// lib/core/theme/app_theme.dart

ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,               // Light mode only
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.surface,
      onPrimary: AppColors.textOnPrimary,
      onSurface: AppColors.textPrimary,
    ),
    fontFamily: 'SF Pro Display',               // Falls back to Roboto on Android
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Color(0xFFB0B0B0),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 0.5,
      space: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDim.radiusLg),
      ),
    ),
  );
}
```

---

## 5. Component Specs

### 5.1 Bottom Navigation Bar
```
Tabs (left to right): Home | Market | Chart | AI | Profile
Icons (Lucide / Material):  home_outlined | bar_chart | trending_up | auto_awesome | person_outline
Selected: color = AppColors.primary, label weight = w600
Unselected: color = #B0B0B0
Background: white, top border 0.5px #E8E8E8
Height: 64px (including safe area padding)
No elevation shadow.
```

### 5.2 Portfolio Card (Home Screen)
```
Container:
  background:    AppColors.primary (#1B56F1)
  border-radius: 20px
  padding:       20px
  margin:        12px 20px

Content layout (top to bottom):
  Label:         "Total Portfolio Value" — 12px, white 75% opacity
  Value:         ₹4,82,310 — 28px, w700, white, letterSpacing -0.5
  Change badge:  "+₹3,210  +0.67% today"
                 background: white 18% opacity, radius pill, 13px w500 white
  ─── spacer 16px ───
  Bottom row (3 equal columns, centered):
    [Invested | Returns | P&L %]
    label: 10px white 65% opacity
    value: 13px w600 white
```

### 5.3 Watchlist / Stock Row
```
Container:
  background:    AppColors.surface (#F8F9FC)
  border-radius: 14px
  padding:       12px 14px
  margin:        0 20px, gap 8px between rows

Left side:
  Ticker logo circle — 36x36px, radius 10px, colored bg, 12px w700 white abbr.
  Stock name:    13px w600 #1A1A1A
  Full name:     11px w400 #999999

Right side:
  Mini sparkline chart — 6 bars, 3px wide, 2px radius, 24px tall
    green bars for gainers, red bars for losers
  Price:         14px w700 #1A1A1A
  Change %:      11px w600 — green if positive, red if negative
```

### 5.4 Market Index Card
```
Container:
  background:    AppColors.surface
  border-radius: 14px
  padding:       12px
  minWidth:      120px (horizontal scroll row)

Index name:  11px w500 #888888
Index value: 15px w700 #1A1A1A
Change:      11px w600 — green or red
```

### 5.5 Filter Chip
```
Height:        30px
Padding:       5px 14px
Border-radius: 100px (pill)
Border:        1px #E0E0E0

Default:  bg white, text #888888 12px w500
Active:   bg AppColors.primary, text white, border primary
```

### 5.6 Chart / Stock Detail Screen
```
Header:
  Stock name:   20px w700 #1A1A1A
  Exchange sub: 12px #888888

Price row:
  Price:        30px w700 #1A1A1A letterSpacing -1
  Change badge: 13px w600 green, bg #DCFCE7, radius pill 20px

Chart area:
  Container:    radius 16px, bg #F8F9FC, height 130px, margin 12px 20px
  Line:         stroke #1B56F1 2.5px
  Area fill:    gradient #1B56F1 → transparent (18% → 0%)
  End dot:      circle r4 filled #1B56F1

Time range selector:
  Buttons: 1D | 1W | 1M | 3M | 1Y
  Active:  bg AppColors.primary, text white, radius 8px
  Default: text #888888

AI Insight strip:
  Container:    bg #EFF4FF, radius 14px, padding 12px 14px
                left border 3px solid #1B56F1
  Label:        "TRADEVISION AI" — 10px w700 #1B56F1 uppercase tracking 0.5px
  Text:         12px #333333 height 1.5

Buy / Sell action row:
  Buy button:   bg #1B56F1, text white 14px w700, radius 12px, height 48px, flex 1
  Sell button:  bg white, text #DC2626 14px w700, border 1.5px #DC2626, radius 12px, height 48px, flex 1
  Gap between:  10px
  Margin:       10px 20px
```

### 5.7 AI Insights Screen

**Summary card:**
```
Same style as Portfolio Card (blue bg, white text)
Label:  11px white 75%
Title:  15px w700 white
Body:   12px white 85% height 1.5
```

**Sentiment row (3 equal cards):**
```
Container: AppColors.surface, radius 14px, padding 12px, centered text
Label:     10px #888888
Value:     18px w700 — colored (green / amber / blue)
Desc:      10px #888888
```

**Recommendation row:**
```
Container: AppColors.surface, radius 14px, padding 12px 14px
Stock:     13px w700 #1A1A1A
Reason:    11px #666666 margin-top 2px
Badge (float right):
  BUY:   bg #DCFCE7, text #15803D, 10px w700, radius pill
  HOLD:  bg #FEF9C3, text #A16207
  SELL:  bg #FEE2E2, text #B91C1C
```

### 5.8 Section Header
```
Layout:   Row, space-between, padding 16px 20px 8px
Title:    15px w700 #1A1A1A
Action:   "See all" or "Filter" — 12px w500 AppColors.primary
```

### 5.9 Greeting / App Bar (Home)
```
Layout:   Row, space-between, padding 16px 20px 8px
Left:
  Line 1: "Good morning," — 13px #888888 w400
  Line 2: User name — 18px w700 #1A1A1A
Right:
  Avatar circle — 38x38px, bg AppColors.primary, initials white 14px w700
```

---

## 6. Screen Map

```
app/
├── screens/
│   ├── home_screen.dart        — Greeting + Portfolio Card + Watchlist
│   ├── market_screen.dart      — Index cards + Filter chips + Top Movers list
│   ├── chart_screen.dart       — Stock detail + Area chart + AI strip + Buy/Sell
│   ├── ai_insights_screen.dart — Summary card + Sentiment row + Recommendations
│   └── profile_screen.dart     — User info, settings, linked accounts
├── widgets/
│   ├── portfolio_card.dart
│   ├── stock_row.dart          — Reusable watchlist/market row
│   ├── ticker_logo.dart        — Colored circle avatar with abbr
│   ├── mini_sparkline.dart     — 6-bar mini chart
│   ├── index_card.dart
│   ├── filter_chip_row.dart
│   ├── ai_insight_strip.dart
│   ├── recommendation_row.dart
│   ├── sentiment_card.dart
│   └── section_header.dart
└── core/
    └── theme/
        ├── app_colors.dart
        ├── app_text_styles.dart
        ├── app_dimensions.dart
        └── app_theme.dart
```

---

## 7. Key UX Rules

- **No dark mode.** `ThemeMode.light` hardcoded in `main.dart`.
- **No emojis anywhere** — use Material / Lucide outlined icons only.
- **All monetary values in INR (₹)** using Indian number format:
  ```dart
  // Format ₹4,82,310 (Indian system)
  final formatter = NumberFormat('#,##,##0', 'en_IN');
  '₹${formatter.format(value)}';
  ```
- **Green = gain, Red = loss** — never invert these colors for any other purpose.
- **Tap targets** — minimum 44x44px for all interactive elements.
- **Horizontal scroll** for index cards — use `ListView(scrollDirection: Axis.horizontal)`.
- **Chart library** — use `fl_chart` package for area/line charts.
- **No elevation shadows** on cards — use `AppColors.surface` bg + `AppColors.border` border for separation instead.
- **Border on elevated surfaces only** — 0.5px `AppColors.border` on white cards sitting on white background.
- **Consistent row spacing** — 8px gap between all stock/watchlist rows.
- **Bottom nav safe area** — wrap tab bar with `SafeArea(bottom: true)`.

---

## 8. pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  fl_chart: ^0.68.0          # Area/line/bar charts
  intl: ^0.19.0              # Indian number formatting
  google_fonts: ^6.2.1       # Optional — if not using system font
  lucide_icons: ^1.0.0       # Icon set (outlined, no fill)
  http: ^1.2.0               # API calls to FastAPI backend
  provider: ^6.1.2           # State management
  cached_network_image: ^3.3.1
```

---

*End of design.md — paste this entire file into Antigravity to generate the TradeVision AI Flutter UI.*
