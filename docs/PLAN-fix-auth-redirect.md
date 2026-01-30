# PLAN-fix-auth-redirect

## Context

- **User Request**: Fix issue where logged-in users are redirected to the landing page and have to log in again.
- **Mode**: Fix/Refactor
- **Status**: Proposed

## Problem Analysis

1. **Symptom**: User logs in -> Landing Page appears -> User logs in again -> Dashboard.
2. **Root Cause**:
    - `navigationProvider` initializes to `NavItem.landing` by default.
    - `LabSenseApp` correctly identifies the user is logged in (`currentUser != null`) and renders `MainLayout`.
    - However, `MainLayout` respects the `navigationProvider` state, which is still `NavItem.landing`.
    - Consequently, `MainLayout` renders the `LandingPage` instead of the `DashboardPage`.

## Proposed Solution

1. **Modify `MainLayout` Initialization**:
    - In `initState`, check if the `navigationProvider` is set to `NavItem.landing` or `NavItem.auth`.
    - If so, and the user is authenticated (which is guaranteed if `MainLayout` is mounted via `LabSenseApp`), immediately update `navigationProvider` to `NavItem.dashboard`.

2. **Safety Check**:
    - Ensure this logic only runs when `mounted` to avoid calling `setState` or `ref.read` on an unmounted widget.
    - Use `addPostFrameCallback` to ensure the provider update happens after the initial build.

## Task Breakdown

- [ ] **Step 1**: Create Plan (This file).
- [ ] **Step 2**: Update `lib/widgets/main_layout.dart` to add the redirection logic in `initState`.
- [ ] **Step 3**: Verify the fix by hot restarting the app.

## Verification

- **Manual Test**:
    1. Log in to the app.
    2. Hot restart the app (simulating a fresh launch).
    3. Verify that the app goes directly to the **Dashboard**, NOT the Landing Page.
