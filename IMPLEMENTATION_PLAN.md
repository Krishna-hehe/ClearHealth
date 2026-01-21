# Optimization Implementation Plan

This plan outlines the steps to implement key optimizations for the LabSense2 application to improve performance, reduce costs, and enhance user experience.

## 1. Lazy Loading for Lab Results
**Goal:** Improve initial rendering performance and memory usage by loading list items only when they are scrolled into view.
**Target File:** `lib/features/lab_results/results_list_page.dart`

### Steps:
1.  **Refactor `ResultsListPage`**:
    *   Replace the existing `SingleChildScrollView` + `Column` with a `CustomScrollView`.
    *   Move the static header content into a `SliverToBoxAdapter`.
    *   Convert the list of result cards into a `SliverList` with a `delegate` (using `SliverChildBuilderDelegate`) to ensure items are built lazily.
    *   This ensures that even if a user has 100+ lab reports, only the visible ones are rendered.

## 2. Image Compression
**Goal:** Reduce upload bandwidth, storage costs, and AI processing latency by compressing images before sending them to the server.
**Target File:** `lib/widgets/main_layout.dart`

### Steps:
1.  **Add Dependency**:
    *   Add `flutter_image_compress` to `pubspec.yaml`.
2.  **Update Upload Logic**:
    *   In `_handleUpload`, check if the selected file is an image (JPG/PNG).
    *   If it is an image, use `FlutterImageCompress.compressWithList` to reduce quality (e.g., to 70-80%).
    *   Pass the compressed bytes to both `storageServiceProvider` and `aiServiceProvider`.

## 3. Code Splitting (PDF Generation)
**Goal:** reduce the initial JavaScript bundle size on the web by deferring the loading of heavy PDF libraries.
**Target File:** `lib/features/lab_results/results_list_page.dart`

### Steps:
1.  **Defer Import**:
    *   Modify the import of `pdf_service.dart` to use `deferred as pdfLib`.
2.  **Async Loading**:
    *   Wrap the usage of `PdfService` in the download button callback with `await pdfLib.loadLibrary()`.
    *   Call `pdfLib.PdfService.generate...`.
