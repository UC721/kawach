// ============================================================
// Exceptions – Infrastructure-layer exceptions
// ============================================================

/// Base class for data-layer exceptions.
///
/// Repositories catch these and return the corresponding [Failure].
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({this.message = 'Server error', this.statusCode});

  @override
  String toString() => 'ServerException($message, statusCode: $statusCode)';
}

class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Cache error'});

  @override
  String toString() => 'CacheException($message)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'Network unavailable'});

  @override
  String toString() => 'NetworkException($message)';
}

class EncryptionException implements Exception {
  final String message;

  const EncryptionException({this.message = 'Encryption failed'});

  @override
  String toString() => 'EncryptionException($message)';
}
