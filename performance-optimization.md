# Performance Optimization Plan

## Overview

This plan addresses critical performance bottlenecks identified in the `LabSense2` application. The primary focus is moving search logic to the server side to handle large datasets efficiently, optimizing list rendering to prevent UI jank, reducing bundle size via deferred loading, and implementing image compression to save bandwidth and storage.

## Project Type

**MOBILE** (Flutter)

## Success Criteria

1. **Server-Side Search**: Lab result filtering occurs on Supabase using `.textSearch()` or `.ilike()`, not in client memory.
2. **Smooth Scrolling**: `ResultsListPage` maintains 60fps during scrolling and searching.
3. **Optimized Bundle**: Heavy libraries are loaded lazily.
4. **Efficient Uploads**: Profile and medication images are compressed before upload (max 800x800, 85% quality).

## Tech Stack

* **Flutter**: Mobile framework.
* **Supabase**: Backend for database and search.
* **Riverpod**: State management for optimized rebuilds.
* **flutter_image_compress**: For client-side image compression.

## File Structure

```
lib/
├── features/
│   ├── lab_results/
│   │   ├── results_list_page.dart       # Update for optimized rendering
│   │   └── ...
│   └── settings/
│       └── settings_page.dart           # Update for image compression
├── core/
│   ├── repositories/
│   │   └── lab_repository.dart          # Add server-side search method
│   ├── providers/
│   │   └── lab_providers.dart           # Update notifier for search query
│   └── services/
│       └── image_service.dart           # New service for compression (optional) or utility
└── ...
```

## Task Breakdown

### Phase 1: Server-Side Search

#### Task 1.1: Update LabRepository

* **Agent**: `mobile-developer`
* **Skill**: `database-design`
* **Goal**: Create a method to fetch lab results with a search query.
* **Input**: `LabRepository.getLabResults` currently accepts limit/offset.
* **Output**: Update `getLabResults` to accept `String? query`. Use Supabase `textSearch` or `ilike` on relevant columns (lab name, test names, date).
* **Verify**: Unit test `getLabResults` with a mock query ensures correct parameters are passed to Supabase client.

#### Task 1.2: Update LabResultsNotifier

* **Agent**: `mobile-developer`
* **Skill**: `state-management`
* **Goal**: Integrate search query into the provider state.
* **Input**: `LabResultsNotifier` currently fetches all.
* **Output**:
  * Add `search(String query)` method.
  * Update `build` or internal fetch logic to pass the query to `repository.getLabResults`.
  * Debounce search input in the UI or Notifier to avoid excessive API calls.
* **Verify**: Typing in the search bar triggers an API call (verified via network inspector) instead of filtering local list.

### Phase 2: UI & Rendering Optimization

#### Task 2.1: Optimize ResultsListPage

* **Agent**: `frontend-specialist` (or `mobile-developer` acting as UI expert)
* **Skill**: `performance-profiling`
* **Goal**: Prevent unnecessary rebuilds.
* **Input**: `ResultsListPage` uses `ref.watch(labResultsProvider)`.
* **Output**:
  * Use `const` for static widgets (headers, empty states).
  * Use `ref.watch(provider.select(...))` where appropriate if only partial data is needed.
  * Ensure `ListView.builder` creates items efficiently.
* **Verify**: Flutter DevTools "Rebuild Stats" shows minimal rebuilds when scrolling or typing.

### Phase 3: Bundle & Assets

#### Task 3.1: Deferred Loading

* **Agent**: `mobile-developer`
* **Skill**: `performance-profiling`
* **Goal**: Load heavy libraries only when needed.
* **Input**: `pdf` library usage.
* **Output**: Ensure `pdf` and `printing` libraries are imported with `deferred as` and loaded just before use (e.g., in the download button callback). Check `fl_chart` usage in Trends.
* **Verify**: Analyze bundle size/startup trace to confirm libraries aren't loaded immediately.

#### Task 3.2: Image Compression

* **Agent**: `mobile-developer`
* **Skill**: `mobile-design`
* **Goal**: Compress images before upload.
* **Input**: `SettingsPage` profile photo upload.
* **Output**:
  * Add `flutter_image_compress` dependency.
  * In `_uploadPhoto` (and other upload methods), compress `XFile` to max 800x800, 85% quality.
  * Upload the compressed bytes.
* **Verify**: Upload a large image, verify stored size in Supabase Storage is significantly smaller.

## Phase X: Verification

* [ ] **Search**: Verify search returns correct results from server (check Network tab).
* [ ] **Scrolling**: Verify 60fps on `ResultsListPage` with 50+ items.
* [ ] **Bundle**: Verify app startup time is not regressed (ideally improved).
* [ ] **Images**: Verify uploaded profile images are reasonable size (<200KB typically).
* [ ] **Lint**: Run `flutter analyze`.
* [ ] **Security**: Ensure search query injection is prevented (Supabase client handles this, but verify logic).
