# Plan: Security, Data Export & Accessibility

**Goal:** Harden application security, enable GDPR-compliant data export, and improve accessibility for screen readers.

## 1. Security Hardening (Agent: Security Auditor)

### Vulnerability 1: Information Leakage

- **Target**: `lib/features/auth/login_page.dart`
- **Change**: Replace raw `e.toString()` in SnackBars with user-friendly messages (e.g., "Invalid email or password", "Service unavailable").



---

## 2. Data Export (Agent: Backend Specialist)

### New Feature: "Download My Data"

- **Target**: `lib/features/settings/settings_page.dart` (Add button)
- **New Service**: `lib/features/settings/data_export_service.dart`
  - **Logic**:
    1. Fetch Profile (Supabase).
    2. Fetch All Lab Results.
    3. Fetch All Prescriptions.
    4. Bundle into a JSON structure.
    5. Trigger file download (Web/Mobile compatible).

---

## 3. Accessibility (Agent: Frontend Specialist)

### Screen Reader Optimization

- **Target**: `LoginPage`, `DashboardPage`, `ResultsListPage`.
- **Changes**:
  - Wrap interactive elements (Buttons, Cards) in `Semantics`.
  - Add `semanticLabel` to Icons and Images (e.g., "Status: Abnormal" instead of just a red icon).
  - Ensure `TextField`s have proper labels for screen readers.

---

## 4. Execution Steps

1. **Security**: Fix Login Page logic.
2. **Backend**: Implement `DataExportService`.
3. **Frontend**: Add Export button & Apply Accessibility tags.
4. **Differentiation**: Verify new password policy and export functionality.
