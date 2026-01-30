# PLAN-ui-modernization.md - Glassmorphic AI Health Interface

> **Goal:** Transform LabSense into a premium, futuristic "AI-Powered Health" platform using Glassmorphism, Deep Dark Mode, and ambient motion.

---

## 🎨 Design Vision: "The Future of Health"

* **Core Aesthetic:** **Glass & Glow (High-Tech)**
* **Color Palette (Dark Mode)**:
  * **Background**: Deep Midnight Blue (`#0B0E14`) instead of standard Slate.
  * **Surface**: Translucent Glass with `BackdropFilter` (Blur 10-20px).
  * **Primary Accent**: Electric Cyan (`#00F0FF`) & Neon Emerald (`#00FF94`) for vitals/action.
  * **Glows**: Soft, localized gradients behind key elements (Ambient Mesh).
* **Typography**:
  * **Headings**: `Outfit` (Geometric, clean, modern).
  * **Body**: `Inter` (Legible, standard).
* **Interaction**:
  * **Floating Dock**: Replace static sidebar with a macOS-style floating glass dock.
  * **Motion**: Dynamic "Swoop" entrance animations (Staggered Slide + Fade) for a high-energy feel.

---

## 🛠️ Phase 1: Foundation (The "Theme Engine")

### 1.1 Update `AppColors` & Theme

* **File**: `lib/core/theme.dart`
* **Action**:
  * Define `MidnightBlue` palette.
  * Create `GlassTheme` extension for reuse (opacity, blur constants).
  * Switch `GoogleFonts` to `Outfit` for display text.

### 1.2 Interactive Background Wrapper

* **New Widget**: `lib/features/shared/ambient_background.dart`
* **Action**:
  * Create a stack with the solid midnight background.
  * Add 2-3 "Aurora" gradient orbs that slowly float/pulse.
  * Wrap `MainLayout` with this to give depth to the whole app.

### 1.3 Glass Card Primitive

* **New Widget**: `lib/widgets/glass_card.dart`
* **Action**:
  * Inputs: `child`, `opacity` (default 0.1), `blur` (default 10).
  * Implementation: `ClipRRect` -> `BackdropFilter` -> `Container` (color: white/0.05) -> `Border` (white/0.1).
  * Replace all current `Card` usages in Dashboard with this.

---

## 🖥️ Phase 2: Navigation Revolution

### 2.1 The Floating Dock

* **Target**: `lib/widgets/main_layout.dart`
* **Action**:
  * Remove the `NavigationRail` (sidebar).
  * Implement a bottom-center (mobile) or left-floating (desktop) container.
  * Style: High blur glass capsule.
  * Animation: Icons scale up slightly on hover.

---

## 📊 Phase 3: Dashboard Transformation

### 3.1 Hero Section ("Bio-Age" & "Wellness")

* **Target**: `lib/features/home/dashboard_page.dart`
* **Action**:
  * Convert "Wellness Score" into a glowing ring gauge (Gradient Arc).
  * Use large `Outfit` typography for the numbers.

### 3.2 Trend Mini-Charts

* **Target**: `lib/features/trends/widgets/ai_insight_card.dart`
* **Action**:
  * Make the internal chart line "Neon" (glow effect on the stroke).
  * Remove grid lines for a cleaner look.

---

## ✅ Experience Verification

### Visual Checks

1. **Contrast**: Ensure Cyan text on Midnight Blue passes WCAG AA.
2. **Performance**: Monitor FPS when "Blur" is active (reduce blur radius if laggy on mobile).
3. **Dark Mode**: Switch toggles and ensure no "White Flash" occurs.

---

## 🚀 Execution Order

1. **Setup Theme**: Define colors and fonts.
2. **Build Primitives**: `GlassCard`, `AmbientBackground`.
3. **Refactor Layout**: Implement Floating Dock.
4. **Polish Dashboard**: Apply glass to widgets.

---

**Ready to start? Run:** `/create`
