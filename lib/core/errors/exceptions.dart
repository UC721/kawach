/// Infrastructure-level exceptions thrown by data sources.
///
/// These are caught by repository implementations and converted to
/// domain [Failure] types before reaching the presentation layer.
class ServerException implements Exception {
  const ServerException([this.message = 'Server error']);
  final String message;
  @override
  String toString() => 'ServerException($message)';
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection']);
  final String message;
  @override
  String toString() => 'NetworkException($message)';
}

class CacheException implements Exception {
  const CacheException([this.message = 'Local cache error']);
  final String message;
  @override
  String toString() => 'CacheException($message)';
}

class AuthException implements Exception {
  const AuthException([this.message = 'Authentication failed']);
  final String message;
  @override
  String toString() => 'AuthException($message)';
}

class EncryptionException implements Exception {
  const EncryptionException([this.message = 'Encryption error']);
  final String message;
  @override
  String toString() => 'EncryptionException($message)';
}
