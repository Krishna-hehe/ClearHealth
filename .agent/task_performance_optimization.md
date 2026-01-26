# Task: Performance Optimization (Option A)

Optimize the application's performance by implementing pagination, enhancing lazy loading, and refining data fetching strategies.

## 1. Pagination for Lab Results
**Goal:** Prevent loading all lab reports at once.
- [x] Update `LabRepository.getLabResults` to support `offset`.
- [x] Implement `LabResultsNotifier` (Riverpod) for paginated state management.
- [x] Update `ResultsListPage` to trigger `fetchNextPage` when scrolling.

## 2. Server-side Distinct Tests
**Goal:** Offload test name extraction to the database.
- [x] Update `distinctTestsProvider` to call `repository.getDistinctTests()`.
- [ ] Verify `SupabaseService.getDistinctTests` is implemented efficiently. (Currently uses limit 50, could be RPC).

## 3. UI Refinement (Infinite Scroll)
**Goal:** Seamlessly load more data.
- [x] Add a loading indicator at the bottom of the lab results list.
- [x] Implement scroll listener or use `VisibilityDetector` for bottom-of-list detection.

## 4. AI Summary Refinement
**Goal:** Reduce token usage and processing time.
- [x] Limit `healthHistoryAiSummaryProvider` to the last 5-10 reports by default.

## 5. Image Compression Verification
**Goal:** Confirm bandwidth savings.
- [x] Audit `MainLayout._handleUpload` for robustness.
