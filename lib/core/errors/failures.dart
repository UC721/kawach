// ============================================================
// Failures – Domain-layer error representations
// ============================================================

/// Base class for all domain failures.
///
/// Features should extend this for module-specific failures
/// so callers can pattern-match on the failure type.
abstract class Failure {
  final String message;
  final int? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure($message, code: $code)';
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred'])
      : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred'])
      : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection'])
      : super(message);
}

class LocationFailure extends Failure {
  const LocationFailure([String message = 'Location unavailable'])
      : super(message);
}

class PermissionFailure extends Failure {
  const PermissionFailure([String message = 'Permission denied'])
      : super(message);
}

class EncryptionFailure extends Failure {
  const EncryptionFailure([String message = 'Encryption error'])
      : super(message);
}
