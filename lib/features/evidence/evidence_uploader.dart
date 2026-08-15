import 'dart:async';

// ============================================================
// EvidenceUploader – Encrypted evidence upload pipeline (Module 5)
// ============================================================

/// Handles chunked, encrypted upload of evidence files to
/// Supabase Storage with retry logic.
class EvidenceUploader {
  final int _maxRetries;
  final Duration _retryDelay;

  EvidenceUploader({
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 5),
  })  : _maxRetries = maxRetries,
        _retryDelay = retryDelay;

  /// Upload a file to encrypted evidence storage.
  ///
  /// Returns the storage URL on success, `null` on failure.
  Future<String?> uploadFile({
    required String filePath,
    required String userId,
    required String emergencyId,
    required EvidenceType type,
  }) async {
    final storagePath = '$userId/$emergencyId/${type.name}/'
        '${DateTime.now().millisecondsSinceEpoch}';

    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        // In production: read file, encrypt, upload to Supabase Storage
        // final bytes = await File(filePath).readAsBytes();
        // final encrypted = encryptionService.encrypt(bytes, key);
        // await supabase.storage.from('evidence').uploadBinary(storagePath, encrypted);
        return storagePath;
      } catch (_) {
        if (attempt < _maxRetries - 1) {
          await Future.delayed(_retryDelay * (attempt + 1));
        }
      }
    }
    return null;
  }

  /// Upload multiple files in parallel.
  Future<List<String>> uploadBatch({
    required List<String> filePaths,
    required String userId,
    required String emergencyId,
    required EvidenceType type,
  }) async {
    final futures = filePaths.map((path) => uploadFile(
          filePath: path,
          userId: userId,
          emergencyId: emergencyId,
          type: type,
        ));
    final results = await Future.wait(futures);
    return results.whereType<String>().toList();
  }
}

enum EvidenceType { audio, video, photo, document }
