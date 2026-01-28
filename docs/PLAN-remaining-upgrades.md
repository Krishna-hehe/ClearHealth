# PLAN-remaining-upgrades.md - Finishing LabSense 2.0 🚀

This plan streamlines the final "Critical Flaws" and "Proposed Upgrades" to make LabSense 2.0 production-ready and market-leading.

## 🔴 Phase 1: Critical Stabilization (The "Must-Haves")

### 1. Enabling the "Upload Engine"

* **Target**: `lib/widgets/main_layout.dart`
* **Action**:
  * Locate and repair the disabled `_handleUpload` method.
  * Integrate `FilePicker` for multi-platform support (Web/Mobile).
  * Connect the uploaded file to `AiService` for Gemini Vision processing.
  * Implementation of the `OcrReviewDialog` to allow users to verify AI extraction.

### 2. State Management "Code Smell" (Instant Auth)

* **Target**: `lib/widgets/main_layout.dart` & `lib/core/navigation.dart`
* **Action**:
  * Refactor the `currentNav` override logic into a dedicated `AuthWrapper` or `RouterGuard`.
  * Eliminate the 0.1s flicker of internal pages for unauthenticated users.

### 3. Mobile Responsiveness (Dynamic Layouts)

* **Target**: `lib/features/home/dashboard_page.dart` & `lib/features/trends/trends_page.dart`
* **Action**:
  * Analyze layouts for "squish" on screens < 600px.
  * Convert remaining dense tables/grids into scrollable Card views.

### 4. Smart Fallbacks (The "Alive" Dashboard)

* **Target**: `lib/features/home/dashboard_page.dart`
* **Action**:
  * Replace hardcoded "Everything looks great!" with a call to `AiService.getWellnessTips`.
  * Ensure even healthy users receive personalized, actionable advice based on their "normal but optimal" ranges.

## 🚀 Phase 2: Intelligent Superpowers (The "Differentiation")

### 1. OCR 2.0 (Normalization Engine)

* **Target**: `lib/core/ai_service.dart` & `lib/core/models.dart`
* **Action**:
  * Implement Lab-specific parsing patterns (Quest, Labcorp).
  * Create a mapping layer for medical terms (e.g., `HbA1c` -> `Hemoglobin A1c`) to ensure unified trending.

### 2. Family Health Profiles (Refinement)

* **Target**: `lib/features/settings/family_profiles_page.dart`
* **Action**:
  * Finalize the "Add Profile" modal with relationship tagging and avatar selection.

## ✅ Verification Plan

### Automated

- **Auth Audit**: Verify redirected users never touch the `Dashboard` build tree.
* **Upload Logic**: Mock `FilePicker` and `AiService` to ensure the flow doesn't break on large files.

### Manual

1. **Mobile Stress Test**: Check every dashboard widget on an iPhone-sized browser viewport.
2. **Healthy User Experience**: Log in with "All Normal" values and verify the AI gives a specific wellness tip.

---
**Next Steps**:
* Run `/create` to start the implementation of Phase 1.
