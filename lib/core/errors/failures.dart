/// Domain-level failure types for KAWACH.
///
/// Repositories expose failures as [Failure] instances instead of
/// throwing raw exceptions to the presentation layer.
abstract class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local cache error']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied']);
}

class EncryptionFailure extends Failure {
  const EncryptionFailure([super.message = 'Encryption error']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation error']);
}

class RateLimitFailure extends Failure {
  const RateLimitFailure([super.message = 'Rate limit exceeded']);
}
