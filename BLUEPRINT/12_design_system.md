# ANIGMAA Design System v1.0

**Owner**: Project Owner (Human)
**Last Updated**: 2026-02-19
**Status**: 🔒 Locked — Do not modify without owner approval

---

## 🎯 Design Principles

| Principle | Meaning |
|-----------|---------|
| **Clean & Editorial** | White space is intentional. Typography does the heavy lifting. |
| **Content-First** | UI is invisible. Content is the hero. |
| **Warm, not Cold** | Warm Lime accent — friendly and approachable, not sterile. |
| **Bold but Minimal** | Strong typography, minimal decoration. No gradients on surfaces. |
| **Indonesian-Native** | All text in Bahasa Indonesia. Design for Indonesian text length. |

> The reference screen is the **Profile Page**. When in doubt, match its feel.

---

## 🎨 Color System

### Key Rule
> **NEVER hardcode hex colors in widgets. ALWAYS use `AppColors.*` tokens.**

### Primary Brand Colors

| Token | Hex | Preview | Use For |
|-------|-----|---------|---------|
| `AppColors.primary` | `#111111` | ⬛ | Text, primary buttons, active icons |
| `AppColors.secondary` | `#BBC863` | 🟨 | Tab indicators, icon containers, accent borders, CTAs |
| `AppColors.electricLime` | `#CCFF00` | 🟩 | **FAB only** — high-energy floating action button |
| `AppColors.white` | `#FFFFFF` | ⬜ | Scaffold, card foregrounds |

### ⚠️ The Two Lime Rule
There are **two** lime colors. They are NOT interchangeable:

```
AppColors.secondary   = #BBC863  ← Warm Lime  → Use everywhere in the UI
AppColors.electricLime = #CCFF00  ← Electric   → FAB button ONLY
```

### Surface Hierarchy

Use the correct surface for the correct depth:

```
Page Background   → AppColors.background  (#FFFFFF)
App Bar / Cards   → AppColors.surface     (#FAFAFA)
Elevated Sections → AppColors.cardSurface (#F8F8F8)   e.g. "Event kamu saat ini" card
Input Fields      → AppColors.surfaceAlt  (#F5F5F5)
```

### Text Hierarchy

```
Headings / body       → AppColors.textPrimary    (#000000)
Descriptions          → AppColors.textEmphasis   (#3D3D3D)
Labels / captions     → AppColors.textSecondary  (#666666)
Timestamps / hints    → AppColors.textTertiary   (#999999)
Disabled              → AppColors.textDisabled   (#CCCCCC)
```

### Accent Surfaces

For tinted backgrounds around accent-colored icons/elements:

```dart
color: AppColors.accentSurface  // 10% Warm Lime — icon container backgrounds
color: AppColors.accentBorder   // 20% Warm Lime — card borders with accent
```

### Semantic Colors

| Token | Use |
|-------|-----|
| `AppColors.error` `#FF3B30` | Errors, destructive actions, "Batal Mengikuti?" |
| `AppColors.success` `#34C759` | Success states |
| `AppColors.warning` `#FFCC00` | Warnings |
| `AppColors.info` `#007AFF` | Informational |

---

## ✍️ Typography

**Font**: Plus Jakarta Sans (Google Fonts)

> **NEVER use inline `GoogleFonts.plusJakartaSans()` in widgets. ALWAYS use `AppTextStyles.*` tokens.**

### Type Scale

| Token | Size | Weight | Use |
|-------|------|--------|-----|
| `AppTextStyles.display` | 40px | w800 | Hero numbers (big stats) |
| `AppTextStyles.h1` | 32px | w800 | Page titles (once per screen) |
| `AppTextStyles.h2` | 24px | w700 | Section titles |
| `AppTextStyles.h3` | 20px | w700 | Card titles, app bar |
| `AppTextStyles.bodyLarge` | 16px | w400 | Post content, descriptions |
| `AppTextStyles.bodyLargeBold` | 16px | w700 | User names, strong labels |
| `AppTextStyles.bodyMedium` | 14px | w400 | List items, secondary content |
| `AppTextStyles.bodyMediumBold` | 14px | w700 | Sub-labels, stat chips |
| `AppTextStyles.bodySmall` | 12px | w400 | Tertiary supporting text |
| `AppTextStyles.caption` | 12px | w500 | Timestamps, location, meta |
| `AppTextStyles.captionSmall` | 11px | w500 | Dense info (rare use) |
| `AppTextStyles.button` | 15px | w700 | All button text |
| `AppTextStyles.label` | 11px | w700 | Badges, status tags, chips |
| `AppTextStyles.tabLabel` | 16px | w700 | Tab bar labels |

### Negative Letter Spacing
Headings use negative letter spacing for a premium, editorial feel:
- `h1`: `-1.0`
- `h2`, `h3`: `-0.5`
- `display`: `-1.5`

---

## 📐 Spacing System

Use multiples of **8px**. Prefer these values:

| Token | Value | Use |
|-------|-------|-----|
| `xs` | 4px | Icon-to-text gap |
| `sm` | 8px | Between inline elements |
| `md` | 12px | Between list items, small gaps |
| `base` | 16px | Default horizontal padding, icon margin |
| `lg` | 20px | Container padding (most screens) |
| `xl` | 24px | Section separators |
| `2xl` | 32px | Between major sections |
| `3xl` | 48px | Hero spacing (e.g. bio to stats gap) |

### Screen Horizontal Padding
```dart
// Standard screen padding
padding: const EdgeInsets.symmetric(horizontal: 20)
```

---

## 🔵 Border Radius

| Size | Value | Use |
|------|-------|-----|
| Small | `8px` | Stat chips, small tags, text buttons |
| Medium | `12px` | Input fields, small cards |
| Large | `16px` | **Standard card radius** (most cards, buttons) |
| XL | `20px` | Bottom sheets |
| Full | `999px` | Pill-shaped buttons, avatars ring |
| Circle | `BoxShape.circle` | Avatars |

> **Default card border radius: 16px**

---

## 🧩 Component Patterns

### Buttons

#### Primary Button (Main CTA)
- Background: `AppColors.primary` (black)
- Text: `AppColors.secondary` (Warm Lime)
- Border radius: `16px`
- Height: `48px` minimum
- Use for: "Beli Tiket", "Ikuti", "Buat Event"

```dart
ElevatedButton(
  onPressed: onTap,
  child: Text('Beli Tiket'),
)
```

#### Outlined Button (Secondary)
- Background: transparent
- Border: `AppColors.border` (1px)
- Text: `AppColors.textPrimary`
- Use for: "Edit Profil", "Mengikuti" (following state)

#### Ghost / Text Button (Tertiary)
- No background, no border
- Text: `AppColors.textPrimary`
- Use for: "Lihat Semua", inline actions

#### Danger Button
- Border: `AppColors.error`
- Text: `AppColors.error`
- Use for: "Batal Mengikuti?", destructive confirmations

---

### Cards

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,      // #FAFAFA
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border, width: 1),
  ),
)
```

**Elevated card section** (inside a card, e.g. profile events hosted):
```dart
color: AppColors.cardSurface,   // #F8F8F8
border: Border.all(color: AppColors.accentBorder, width: 1),
```

---

### Tab Bar
- Indicator: `AppColors.secondary` (Warm Lime), `3px` height, `TabBarIndicatorSize.label`
- Both label styles: `AppTextStyles.tabLabel` (same for selected & unselected)
- Background when sticky: `AppColors.background` (white)
- Bottom divider: `AppColors.divider` (`#EEEEEE`, `1px`)

---

### Icon Containers
When an icon needs a tinted background:
```dart
Container(
  padding: const EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: AppColors.accentSurface,   // 10% Warm Lime
    borderRadius: BorderRadius.circular(10),
  ),
  child: Icon(Icons.event, color: AppColors.secondary, size: 20),
)
```

---

### Stat Chips (e.g. profile stats)
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surfaceAlt,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    child: Text(label, style: AppTextStyles.bodyMediumBold.copyWith(fontSize: 13)),
  ),
)
```

---

### Avatars
```dart
Container(
  width: size, height: size,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: AppColors.border, width: 1),
  ),
  child: ClipOval(child: ...),
)
```

---

### Loading / Progress
```dart
CircularProgressIndicator(color: AppColors.secondary)
```

---

### Empty States
```dart
Icon(Icons.event_outlined, size: 64, color: AppColors.border)
Text('Belum ada event', style: AppTextStyles.bodyLargeBold.copyWith(color: AppColors.textTertiary))
```

---

### Shadows

Use sparingly. Only on floating elements:
```dart
BoxShadow(
  color: AppColors.primary.withValues(alpha: 0.05),
  blurRadius: 10,
  offset: Offset(0, 4),
)
```

Most cards and containers: **elevation: 0** (flat design).

---

## 🚫 Do's and Don'ts

### ✅ DO
- Use `AppColors.*` tokens always
- Use `AppTextStyles.*` tokens always
- Use `16px` border radius for cards
- Use `20px` horizontal padding for screens
- Keep backgrounds white or `#FAFAFA` — never colored backgrounds on full screens
- Use `AppColors.secondary` (Warm Lime) for accent elements
- Use bold typography (`w700+`) for interactive elements

### ❌ DON'T
- Hardcode colors (`Color(0xFFBBC863)` → use `AppColors.secondary`)
- Use `Colors.grey[x]` → use `AppColors.textSecondary/Tertiary`
- Use `Colors.white` → use `AppColors.white` or `AppColors.background`
- Use `#CCFF00` (`electricLime`) anywhere except the FAB
- Add gradients to surface containers
- Use shadows on regular cards (flat design)
- Use multiple font families — Plus Jakarta Sans only
- Override theme values inline in widgets

---

## 📁 Key Files

| File | Purpose |
|------|---------|
| `core/theme/app_colors.dart` | All color tokens |
| `core/theme/app_text_styles.dart` | All typography tokens |
| `core/theme/app_theme.dart` | Material 3 ThemeData |
| `presentation/widgets/profile/profile_header_widget.dart` | Reference implementation |

---

## 🔗 Related

- [`08_coding_standards.md`](08_coding_standards.md) — BLoC patterns, navigation
- [`06_file_organization.md`](06_file_organization.md) — Where to put new files
- [`11_state_machines.md`](11_state_machines.md) — State-driven UI rules
