# Plan: Enterprise Security & Next-Gen Performance

**Goal:** Elevate LabSense2 to meet enterprise security standards (HIPAA audit readiness) and achieve native-like web performance (Wasm/PWA).

## 1. Enterprise Security (Option A)

### 1.1 Audit Logging System
- **Objective:** Track *who* accessed *what* sensitive data (HIPAA requirement).
- **Implementation:**
  - Create `access_logs` table in Supabase (user_id, action, resource_id, timestamp, ip_address).
  - Create `AuditService` in Dart to easily log events.
  - Instrument critical actions: `VIEW_LAB_RESULT`, `EXPORT_DATA`, `LOGIN_SUCCESS`, `UPDATE_PATIENT_DATA`.

### 1.2 RLS Policy Hardening
- **Objective:** Ensure data isolation is absolute.
- **Implementation:**
  - Review `lab_results` and `profiles` policies.
  - Explicitly deny public access.
  - Verify that `auth.uid() = user_id` is prevalent.

### 1.3 Content Security Policy (CSP)
- **Objective:** Prevent XSS attacks.
- **Implementation:**
  - Add `<meta>` tag to `web/index.html`.
  - Restrict `script-src` to 'self', 'unsafe-inline' (Flutter legacy), and trusted CDNs (Supabase, Google Maps if used).

---

## 2. Web Performance & PWA (Option B)

### 2.1 WebAssembly (Wasm) Readiness
- **Objective:** Achieve near-native execution speed.
- **Implementation:**
  - Audit dependencies for Wasm compatibility (cleaner JS interop).
  - Update `web/index.html` script loading to support Wasm GC.
  - **Note**: Requires HTTPS and specific server headers (`Cross-Origin-Opener-Policy`, `Cross-Origin-Embedder-Policy`).

### 2.2 Advanced Service Worker (Offline Assets)
- **Objective:** Instant load on repeat visits.
- **Implementation:**
  - Configure `pwa` strategy in `web/manifest.json`.
  - Cache core fonts, icons, and the main `main.dart.js` / `main.dart.wasm` aggressively.

### 2.3 Client-Side Image Optimization
- **Objective:** Reduce upload bandwidth and storage costs.
- **Implementation:**
  - Integrate `flutter_image_compress`.
  - Resize/Compress lab report photos *before* sending to Supabase Storage.
  - Limit max dimension to 2048px, Quality 80%.

---

## 3. Execution Strategy

### Phase 1: Security Foundation
1. Create `AuditService` & Supabase Table.
2. Add Logging calls to `LabRepository` and `AuthService`.
3. Apply CSP headers.

### Phase 2: Performance Boost
1. Add Image Compression logic to `StorageService`.
2. Update Web Entrypoint (`index.html`) for headers/Wasm.
3. Verify PWA Manifest.

### Phase 3: Verification
1. Verify Audit Logs appear in Supabase.
2. Verify Wasm build (if environment supports) or fallback to JS.
3. Test Image Upload size reduction.
