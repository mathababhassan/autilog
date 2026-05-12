# Design System Usage Guide

All design tokens are defined in `lib/core/theme/`. Add the following import at the top of any screen or widget file to access them:

```dart
import 'package:autilog/core/theme/theme.dart';
```

---

## Colors — `AppColors`

Use `AppColors` whenever a widget requires a color value.

```dart
Container(color: AppColors.primary)            // orange #FA8601
Icon(Icons.person, color: AppColors.secondary) // teal #006675

Text('Hello', style: TextStyle(color: AppColors.textMain))        // standard text color
Text('Hint',  style: TextStyle(color: AppColors.textPlaceholder)) // dimmed / placeholder
Text('Error', style: TextStyle(color: AppColors.error))           // red
```

**Reference table:**

| Token | Purpose |
|---|---|
| `AppColors.primary` | Main brand color (orange) — used for primary buttons and highlights |
| `AppColors.secondary` | Secondary brand color (teal) — used for links, active borders, and active states |
| `AppColors.textMain` | Default color for all body text |
| `AppColors.textPlaceholder` | Color for input hints and secondary labels |
| `AppColors.textDisabled` | Color for disabled or inactive text |
| `AppColors.error` | Color for validation errors and destructive actions |
| `AppColors.surfaceModal` | Background color for modals and bottom sheets |
| `AppColors.inputFill` | Background color inside text input fields |

---

## Text Styles — `AppTextStyles`

Use `AppTextStyles` as the value for any `style` parameter on a `Text` widget.

```dart
Text('Welcome', style: AppTextStyles.heading1)
Text('Section', style: AppTextStyles.subtitle)
Text('This is body copy.', style: AppTextStyles.body)
Text('12 Jan 2025', style: AppTextStyles.caption)
```

**Reference table:**

| Token | Size | Weight | Intended use |
|---|---|---|---|
| `AppTextStyles.display` | 28 / Bold | Large hero text on a screen |
| `AppTextStyles.heading1` | 22 / Bold | Screen titles |
| `AppTextStyles.heading2` | 20 / Medium | Page headers |
| `AppTextStyles.subtitle` | 16 / Medium | Section titles, card headers |
| `AppTextStyles.body` | 15 / Regular | All standard body text |
| `AppTextStyles.caption` | 13 / Regular | Timestamps, helper text |
| `AppTextStyles.tag` | 12 / Regular | Chips and tags (uppercase) |

### Overriding a single property with `.copyWith()`

Each predefined style already has a font, size, weight, and color set. When only one of those properties needs to differ — for example, a body text that should appear in grey instead of the default dark color — use `.copyWith()` to create a modified copy while keeping all other properties unchanged.

```dart
// Default body style: size 15, weight 400, color textMain (dark)
AppTextStyles.body

// Same style, but with a different color — all other properties are preserved
AppTextStyles.body.copyWith(color: AppColors.textPlaceholder)

// Same style, but bold
AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)
```

This avoids rewriting the full style definition every time a small variation is needed.

---

## Spacing — `AppSpacing`

Use `AppSpacing` constants instead of writing raw pixel values. All values follow an 8pt spacing grid defined in the Figma design.

```dart
Padding(padding: EdgeInsets.all(AppSpacing.lg))
Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin))
SizedBox(height: AppSpacing.sm)
BorderRadius.circular(AppSpacing.borderRadius)
```

**Reference table:**

| Token | Value | Intended use |
|---|---|---|
| `AppSpacing.xs` | 4px | Tight gaps between small elements |
| `AppSpacing.sm` | 8px | Space between an icon and its label |
| `AppSpacing.md` | 12px | Vertical padding inside input fields |
| `AppSpacing.lg` | 16px | Inner padding for cards |
| `AppSpacing.screenMargin` | 20px | Horizontal margin on all screens |
| `AppSpacing.gutter` | 24px | Space between layout columns |
| `AppSpacing.borderRadius` | 4px | Corner radius for all rounded elements |

---

## Full example

```dart
import 'package:autilog/core/theme/theme.dart';

Padding(
  padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Patients', style: AppTextStyles.heading1),
      SizedBox(height: AppSpacing.sm),
      Text(
        '3 active sessions',
        style: AppTextStyles.caption.copyWith(color: AppColors.textPlaceholder),
      ),
    ],
  ),
)
```
