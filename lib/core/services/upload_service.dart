import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:mime/mime.dart';
import '../providers/core_providers.dart';
import '../providers/lab_providers.dart';

class UploadState {
  final bool isUploading;
  final String? error;
  final String? status;

  UploadState({this.isUploading = false, this.error, this.status});

  UploadState copyWith({bool? isUploading, String? error, String? status}) {
    return UploadState(
      isUploading: isUploading ?? this.isUploading,
      error: error,
      status: status,
    );
  }
}

class UploadController extends StateNotifier<UploadState> {
  final Ref _ref;

  UploadController(this._ref) : super(UploadState());

  Future<Map<String, dynamic>?> pickAndUpload(dynamic context) async {
    try {
      state = state.copyWith(isUploading: true, status: 'Picking file...');

      final result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        state = UploadState();
        return null;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) throw Exception('Could not read file bytes');

      final fileName = file.name;
      final mimeType = lookupMimeType(fileName) ?? 'image/jpeg';

      state = state.copyWith(status: 'Uploading & Analyzing...');

      // Run parallel tasks:
      // 1. Upload to Storage (compressed automatically by service)
      final uploadFuture = _ref
          .read(storageServiceProvider)
          .uploadLabReport(bytes, fileName);

      // 2. AI Parse (Gemini Vision)
      final parseFuture = _ref
          .read(aiServiceProvider)
          .parseLabReport(bytes, mimeType);

      final results = await Future.wait([uploadFuture, parseFuture]);
      final storagePath = results[0] as String?;
      final parsedData = results[1] as Map<String, dynamic>?;

      if (storagePath == null) throw Exception('Failed to upload to storage');
      if (parsedData == null) {
        throw Exception(
          'AI failed to parse the document. Please try a clearer photo.',
        );
      }

      state = state.copyWith(
        isUploading: false,
        status: 'Waiting for confirmation...',
      );

      return {...parsedData, 'storage_path': storagePath};
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> saveResult(Map<String, dynamic> finalData) async {
    try {
      state = state.copyWith(
        isUploading: true,
        status: 'Saving to database...',
      );

      await _ref.read(labRepositoryProvider).createLabResult(finalData);

      // Refresh data
      _ref.invalidate(labResultsProvider);
      _ref.invalidate(recentLabResultsProvider);
      _ref.invalidate(dashboardAiInsightProvider);
      _ref.invalidate(optimizationTipsProvider);

      state = UploadState();
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
      rethrow;
    }
  }

  void reset() {
    state = UploadState();
  }
}

final uploadControllerProvider =
    StateNotifierProvider<UploadController, UploadState>((ref) {
      return UploadController(ref);
    });
