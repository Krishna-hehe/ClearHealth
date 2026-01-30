# PLAN-ui-modernization-dashboard.md - Premium Glassmorphic Dashboard

> **Goal:** Elevate the Dashboard experience to a "Premium Glassmorphic" standard with dynamic wellness gauges, categorized stats, and sparkline micro-insights.

---

## 🎨 Design Vision: "Premium Glassmorphic Experience"

* **Aesthetic**: Deep depth, neon accents, glass surfaces, and fluid motion.
* **Key Elements**:
  * **Dynamic Neon Arcs**: Visual feedback based on health scores.
  * **Categorized Lab Data**: Logical grouping for better cognitive load management.
  * **Micro-Insights**: Immediate trend visibility via sparklines.
  * **Premium Interactions**: Shimmer effects and hover states.

---

## 🛠️ Phase 2: Dashboard Execution Plan

### 3.1 Wellness Gauge Dynamics

* **Component**: `WellnessGauge` (or extract from Dashboard)
* **Logic**:
  * **Input**: `wellnessScore` (0-100).
  * **Dynamic Color**:
    * > 90: Cyan Pulse (`Colors.cyanAccent`) -> "Excellent"
    * 75-90: Green Glow (`Colors.greenAccent`) -> "Good"
    * < 75: Amber Glow (`Colors.amberAccent`) -> "Needs Attention"
  * **Visuals**:
    * Fluorescent/Neon effect using `BoxShadow` with spread.
    * Animated arc filling.

### 3.2 Lab Results Architecture Redesign

* **Component**: `DashboardPage` / `RecentLabsList`
* **Structure**: Transition from flat list to **Categorized Sections**.
  * **Groups**: "Metabolic", "Blood Count", "Vitals", etc. (Mock data or deduced from result types).
* **UI**:
  * Use `GlassCard` for each category container.
  * Inside, list items with subtle separators.

### 3.3 Micro-Insights (Sparklines)

* **Component**: `LabResultCard`
* **Feature**: Add a `MiniSparkline` widget to the right side of the result row.
  * **Data**: Previous 3-5 data points (mock trend if history unavailable).
  * **Style**: Thin line (2px), color-coded by trend (Up/stable/down).
  * **No Interaction**: Purely visual "glanceable" data.

### 3.4 Premium Interactions (Shimmer)

* **Component**: `GlassShimmer` wrapper.
* **Behavior**:
  * **On Load**: A distinct white/transparent gradient wipe across the card.
  * **On Hover**: (Desktop) A subtle re-trigger of the shimmer or a glow intensification.

---

## 🚀 Step-by-Step Implementation

1. **Dependencies**: Verify `GlassCard` and `AmbientBackground` usage.
2. **Wellness Gauge**: Refactor current score display into `DynamicWellnessGauge`.
3. **Sparkline Widget**: Create `MiniSparkline`.
4. **Refactor Dashboard**:
    * Implement Categorization logic.
    * Integrate Sparklines into list items.
    * Apply Shimmer.
5. **Verify**: Check aesthetics against dark mode background.

---
