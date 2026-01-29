# Project Plan: Offline-First UX & Smart AI Predictions

**Goal:** Transform LabSense2 into a resilient, intelligent health companion by enabling full offline capabilities and proactive AI health predictions.

## 1. Offline-First "Pro" Architecture

**Objective:** Ensure the app works seamlessly without internet, queuing changes for later sync.

### Dependencies

- Add `connectivity_plus` for network state monitoring.
- Use existing `Hive` infrastructure for the Sync Queue.

### [Core] Sync Infrastructure

- **Create `SyncService`:**
  - Manages a persistent queue of offline actions (e.g., `ADD_LAB`, `UPDATE_PROFILE`).
  - Listen for network restoration.
  - Process queue sequentially when online.
- **Update `LabRepository`:**
  - Check connectivity before Supabase calls.
  - If offline:
    - Save to local Cache/Hive immediately.
    - Add action to Sync Queue.
    - Return success (optimistic UI).

### [UX] Offline Indicators

- **Dashboard Banner:** "You are offline. Changes will sync when connected." (Dismissible, Non-intrusive).
- **Status Badges:** Add "Pending Sync" icon to lab reports or items created while offline.
- **Conflict Handling:** Simple "Last Write Wins" strategy for V1 to keep complexity manageable.

---

## 2. Smart AI Insights (Predictive Health)

**Objective:** Move from "reactive" analysis to "proactive" health forecasting.

### [AI] Predictive Engine

- **Enhance `AiService`:**
  - Add `getHealthPredictions(List<LabReport> history)`.
  - Prompt Engineering: "Based on these 3 HbA1c readings over 6 months, predict the next value if trends continue."
  - Risk Analysis: "Your cholesterol is trending up 5% per month. Projected risk level: High by Dec 2026."

### [UI] Smart Insight Widgets

- **`SmartInsightCard` (Dashboard):**
  - "Health Forecast": Line chart with dotted "Predicted" line.
  - "Actionable Nudge": "To avoid reaching 6.5%, try increasing fiber intake by 5g/day."
- **Trend Page Integration:**
  - Overlay prediction intervals on existing trend charts.

---

## 3. Implementation Phases

### Phase 1: Foundation (Offline)

- [ ] Add `connectivity_plus` dependency.
- [ ] Implement `SyncService` with Hive backing.
- [ ] Refactor `LabRepository` for offline-write intercepts.

### Phase 2: Offline UX

- [ ] Create `OfflineBanner` widget.
- [ ] Add `SyncStatus` indicators to Result Cards.
- [ ] Test "Airplane Mode" workflows.

### Phase 3: Smart AI

- [ ] Implement `getHealthPredictions` in `AiService`.
- [ ] Build `SmartInsightCard`.
- [ ] Integrate predictions into Trends Dashboard.

---

## 4. Verification

- **Offline Test:** Turn off WiFi -> Add Report -> Check Cache -> Turn on WiFi -> Verify Supabase Sync.
- **AI Test:** Verify predictions return valid JSON and render correctly on the Dashboard.
