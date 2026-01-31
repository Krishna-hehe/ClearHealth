# PLAN-faster-uploads

## 1. Context

- **Goal**: Optimize file upload speed and UX for LabSense2.
- **Strategy**: Option A - Parallel Processing + Compression.
- **Key Changes**:
  - Parallelize storage upload and AI parsing.
  - Ensure image compression is effective.

## 2. Technical Approach

### A. Parallel Execution (Backend/Logic)

- **Current**: Serial execution (Upload -> Wait -> Parse -> Wait).
- **New**: `Future.wait([uploadTask, parseTask])`.
- **File**: `lib/core/services/upload_service.dart`

### B. Compression Optimization (Performance)

- **Current**: Skips compression on Web (`kIsWeb`).
- **New**: Evaluate if Web compression is feasible/beneficial or if we should just rely on parallelization for now.
  - *Decision*: For now, we will focus on the parallelization as the primary speedup, and ensure the existing compression logic is correctly applied where supported.
- **File**: `lib/core/services/storage_service.dart`

## 3. Task Breakdown

### Phase 1: Implementation

- [ ] **Task 1.1**: Update `UploadController` in `lib/core/services/upload_service.dart`.
  - Modify `pickAndUpload` to trigger `storageServiceProvider.uploadLabReport` and `aiServiceProvider.parseLabReport` simultaneously.
  - Handle combined results.
  - Update `UploadState` messages to reflect concurrent processing ("Processing..." instead of specific steps).
- [ ] **Task 1.2**: Review and optimize `StorageService` in `lib/core/services/storage_service.dart`.
  - Ensure `uploadLabReport` returns the `path` correctly.
  - (Optional) Adjust compression quality if needed.

### Phase 2: Verification

- [ ] **Task 2.1**: Manual Verification.
  - specific checks for upload speed improvement.
  - Verify data consistency (path and parsed data both present).

## 4. Agent Assignments

- **Core Logic**: `mobile-developer` (handling Flutter logic & Services).
- **Verification**: `test-engineer` (or self-verification via manual checks).

## 5. Next Steps

- Approve this plan to start implementation.
