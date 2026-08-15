import 'package:flutter/material.dart';

/// GoRouter configuration for KAWACH clean-architecture navigation.
///
/// Route tree mirrors feature modules so each feature owns its sub-routes.
/// Replace placeholder widgets with actual feature screens during migration.
final appRouter = _AppRouter();

class _AppRouter {
  // Route path constants
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String sos = '/sos';
  static const String map = '/map';
  static const String safeRoute = '/safe-route';
  static const String safeWalk = '/safe-walk';
  static const String fakeCall = '/fake-call';
  static const String guardians = '/guardians';
  static const String community = '/community';
  static const String settings = '/settings';
  static const String profile = '/profile';
}
